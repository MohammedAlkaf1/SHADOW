// HTTP client for the Shadow Platform backend (D:\Shadow\platform,
// docs/API.md). Talks to the platform's Bearer-JWT `/api/*` endpoints —
// completely separate from the Deepgram/Gemini calls in ai_client.dart,
// which this file never touches.
//
// Design notes:
// - Follows the same convention as ai_client.dart: plain `package:http`
//   calls, no persistent client, results returned as a success/failure
//   wrapper (never throws) so callers don't need try/catch everywhere.
// - Offline-first: every read goes through AppPrefs' cache first as a
//   fallback. A failed network call never blocks a mode from working — it
//   just means the app keeps using the last-known-good profile/directives.
// - Usage events are buffered locally and flushed as a batch (never one
//   HTTP call per event) — see queueUsageEvent/flushQueuedEvents.
// - Never sends audio, images, or PDF content — only abstract event
//   metadata (eventType + a small JSON payload with no transcript/PII).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_prefs.dart';
import 'adaptation_directives.dart';

/// `--dart-define-from-file=env.json` value, defaulting to the local dev
/// server. See env.example.json / README.
const String kPlatformBaseUrl = String.fromEnvironment(
  'PLATFORM_BASE_URL',
  defaultValue: 'http://localhost:3000/api',
);

/// Generic success/failure result — mirrors AiResult's shape in
/// ai_client.dart so callers across the app follow one convention.
class PlatformResult<T> {
  const PlatformResult.success(T data)
      : _data = data,
        errorMessage = null;
  const PlatformResult.failure(this.errorMessage) : _data = null;

  final T? _data;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null;
  T get data => _data as T;
}

class StudentPlatformProfile {
  const StudentPlatformProfile({
    required this.enabledTools,
    required this.directives,
    required this.raw,
  });

  final List<String> enabledTools;
  final AdaptationDirectives directives;

  /// The full decoded JSON response — cached verbatim so a later offline
  /// read can reconstruct this object without re-deriving anything.
  final Map<String, dynamic> raw;

  factory StudentPlatformProfile.fromJson(Map<String, dynamic> json) =>
      StudentPlatformProfile(
        enabledTools: (json['enabledTools'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        directives: AdaptationDirectives.fromJson(
            json['adaptationDirectives'] as Map<String, dynamic>? ?? const {}),
        raw: json,
      );
}

class PlatformClient {
  PlatformClient._();

  static Timer? _flushTimer;
  static final List<Map<String, dynamic>> _memoryQueue = [];
  static bool _memoryQueueLoaded = false;

  // In-memory only — never written to disk. Lives for as long as the app
  // process does; a fresh cold start always begins with this null, and (if
  // "remember me" was on) tryRestoreSession() repopulates it from the
  // persisted refresh token before the student ever sees a login screen.
  static String? _accessToken;

  /// Test-only: this static field otherwise persists across every test in
  /// the same run (Dart tests share one isolate), silently short-circuiting
  /// tryRestoreSession()'s "is there already an in-memory token" check for
  /// any test after the first one that logs in. Call from setUp() to get a
  /// genuinely fresh-process state.
  @visibleForTesting
  static void resetForTesting() {
    _accessToken = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _memoryQueue.clear();
    _memoryQueueLoaded = false;
  }

  // ── Auth ─────────────────────────────────────────────────────────────

  static Uri _uri(String path) => Uri.parse('$kPlatformBaseUrl$path');

  /// [rememberMe]: if true, the platform's refresh token (30-day-lived) is
  /// persisted to secure storage so [tryRestoreSession] can silently renew
  /// the session on the next cold start. If false, nothing survives this
  /// app process — and any refresh token remembered by a previous login is
  /// explicitly cleared, since this login is a deliberate "don't remember
  /// me" choice. The password itself is never persisted either way.
  static Future<PlatformResult<void>> login(
    String email,
    String password, {
    required bool rememberMe,
  }) async {
    try {
      final response = await http
          .post(
            _uri('/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return PlatformResult.failure(_extractError(
            response, 'تعذر تسجيل الدخول. تحقق من البريد الإلكتروني وكلمة المرور.'));
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      _accessToken = body['accessToken'] as String;
      debugPrint('🔐 PlatformClient.login: succeeded, rememberMe=$rememberMe');
      if (rememberMe) {
        final refreshToken = body['refreshToken'];
        if (refreshToken is String) {
          await AppPrefs.setRefreshToken(refreshToken);
        } else {
          debugPrint(
              '⚠️ PlatformClient.login: rememberMe was on but the response '
              'had no refreshToken (key present: ${body.containsKey('refreshToken')}, '
              'value: $refreshToken) — nothing will be restorable on next launch.');
        }
      } else {
        await AppPrefs.clearRefreshToken();
      }
      return const PlatformResult.success(null);
    } catch (e) {
      debugPrint('⚠️ PlatformClient.login failed: $e');
      return const PlatformResult.failure(
          'تعذر الاتصال بالمنصة. تحقق من اتصالك بالإنترنت.');
    }
  }

  /// Exchanges the persisted refresh token (if any) for a new access token.
  /// The platform's /auth/refresh does not rotate the refresh token itself
  /// (it only returns a new accessToken), so the stored refresh token is
  /// left as-is on success.
  static Future<bool> refreshToken() async {
    final refresh = await AppPrefs.getRefreshToken();
    if (refresh == null) {
      debugPrint('🔐 PlatformClient.refreshToken: no stored refresh token');
      return false;
    }
    try {
      final response = await http
          .post(
            _uri('/auth/refresh'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint(
            '⚠️ PlatformClient.refreshToken: platform rejected the stored '
            'refresh token — status ${response.statusCode}');
        return false;
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      _accessToken = body['accessToken'] as String;
      debugPrint('🔐 PlatformClient.refreshToken: succeeded');
      return true;
    } catch (e) {
      debugPrint('⚠️ PlatformClient.refreshToken failed: $e');
      return false;
    }
  }

  /// Called once on app startup (splash screen), before ever showing the
  /// login screen. Silently renews the session from the persisted "remember
  /// me" refresh token, if one exists. Returns false (and clears the stale
  /// refresh token) if none is stored, or if the stored one is rejected —
  /// either way the caller then shows a normal login screen.
  static Future<bool> tryRestoreSession() async {
    if (_accessToken != null) {
      debugPrint('🔐 PlatformClient.tryRestoreSession: already have a '
          'session in memory');
      return true;
    }
    final restored = await refreshToken();
    if (!restored) await AppPrefs.clearRefreshToken();
    debugPrint('🔐 PlatformClient.tryRestoreSession: restored=$restored');
    return restored;
  }

  /// Whether this running app process currently holds an access token —
  /// true immediately after [login] or a successful [tryRestoreSession],
  /// false at the start of every fresh process until one of those runs.
  static Future<bool> get isLoggedIn async => _accessToken != null;

  /// Clears both the in-memory access token and the persisted refresh
  /// token, regardless of whether "remember me" was ever used.
  static Future<void> logout() async {
    _accessToken = null;
    await AppPrefs.clearRefreshToken();
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  // ── Student profile / support plan (offline-first) ──────────────────

  /// Fetches the student's profile+directives from the platform. On any
  /// network/auth failure, falls back to the last cached copy (if any) so
  /// the app keeps working offline — a failed call here must never block a
  /// mode. Returns failure only when there's NEITHER a fresh fetch NOR a
  /// cache to fall back to (e.g. first-ever launch with no connectivity).
  static Future<PlatformResult<StudentPlatformProfile>>
      getStudentProfile() async {
    final fresh = await _authedGet('/student/profile');
    if (fresh != null) {
      await AppPrefs.setCachedProfileJson(fresh);
      return PlatformResult.success(StudentPlatformProfile.fromJson(fresh));
    }

    final cachedJson = await AppPrefs.getCachedProfileJson();
    if (cachedJson != null) {
      try {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        return PlatformResult.success(
            StudentPlatformProfile.fromJson(decoded));
      } catch (e) {
        debugPrint('⚠️ PlatformClient: failed to parse cached profile: $e');
      }
    }

    return const PlatformResult.failure(
        'تعذر جلب بيانات الملف الشخصي من المنصة، ولا توجد نسخة محفوظة سابقاً.');
  }

  static Future<PlatformResult<Map<String, dynamic>>> getSupportPlan() async {
    final json = await _authedGet('/student/support-plan');
    if (json == null) {
      return const PlatformResult.failure('تعذر جلب خطة الدعم من المنصة.');
    }
    return PlatformResult.success(json);
  }

  // ── Usage events (buffered, batched, offline-safe) ──────────────────

  /// Queues one usage event locally; does NOT send it immediately. Flushed
  /// as a batch every 60 seconds (see [startAutoFlushTimer]) or when a mode
  /// screen calls [flushQueuedEvents] on close, whichever happens first.
  /// Never include audio/image/PDF content in [payload] — abstract metadata
  /// only (event type, mode name, tool name, error type — no transcripts,
  /// no PII).
  static Future<void> queueUsageEvent(
    String eventType, {
    Map<String, dynamic>? payload,
  }) async {
    await _ensureQueueLoaded();
    _memoryQueue.add({
      'eventType': eventType,
      if (payload != null) 'payload': payload,
      'occurredAt': DateTime.now().toUtc().toIso8601String(),
    });
    await AppPrefs.setQueuedEvents(_memoryQueue);
  }

  static Future<void> _ensureQueueLoaded() async {
    if (_memoryQueueLoaded) return;
    _memoryQueue.addAll(await AppPrefs.getQueuedEvents());
    _memoryQueueLoaded = true;
  }

  /// Sends every queued event as one batch POST /api/events. On success the
  /// queue is cleared. On failure (offline, server error, rate-limited) the
  /// queue is left intact for the next trigger — no aggressive retry loop,
  /// just "try again next time something calls flush".
  static Future<void> flushQueuedEvents() async {
    await _ensureQueueLoaded();
    if (_memoryQueue.isEmpty) return;

    final token = _accessToken;
    if (token == null) return; // not logged in — nothing to flush against

    final batch = List<Map<String, dynamic>>.from(_memoryQueue);
    try {
      final response = await http
          .post(
            _uri('/events'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'events': batch}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _memoryQueue.removeRange(0, batch.length);
        await AppPrefs.setQueuedEvents(_memoryQueue);
      } else if (response.statusCode == 401) {
        // Access token expired — refresh once and let the NEXT flush retry;
        // avoids retry-looping within this call.
        await refreshToken();
      }
      // Any other status (429 rate-limited, 5xx, etc.): leave queued,
      // try again on the next scheduled/triggered flush.
    } catch (e) {
      debugPrint('⚠️ PlatformClient.flushQueuedEvents failed (will retry later): $e');
    }
  }

  /// Starts the 60-second auto-flush timer. Idempotent — safe to call from
  /// multiple places (e.g. app startup and after login); only one timer is
  /// ever active.
  static void startAutoFlushTimer() {
    _flushTimer ??= Timer.periodic(const Duration(seconds: 60), (_) {
      flushQueuedEvents();
    });
  }

  static void stopAutoFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  // ── Internal helpers ─────────────────────────────────────────────────

  /// GETs an authenticated endpoint, transparently retrying once after a
  /// token refresh on 401. Returns null on any failure (network error,
  /// non-200 after retry, etc.) — callers fall back to cache.
  static Future<Map<String, dynamic>?> _authedGet(String path) async {
    final token = _accessToken;
    if (token == null) return null;

    try {
      var response = await http.get(
        _uri(path),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (!refreshed) return null;
        response = await http.get(
          _uri(path),
          headers: {'Authorization': 'Bearer $_accessToken'},
        ).timeout(const Duration(seconds: 15));
      }

      if (response.statusCode != 200) return null;
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ PlatformClient: GET $path failed: $e');
      return null;
    }
  }

  static String _extractError(http.Response response, String fallback) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['error'] is String) return body['error'] as String;
    } catch (_) {
      // fall through to fallback
    }
    return fallback;
  }
}
