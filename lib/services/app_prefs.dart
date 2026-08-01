// Local, on-device settings backed by shared_preferences.
//
// Originally: nothing here left the device (quick-contact number, first-run
// consent flag, transcript retention — no accounts, no backend). As of the
// platform integration, this also caches the platform session (JWTs), the
// last successfully-fetched student profile/directives (for offline-first
// use), and a locally-queued batch of not-yet-sent usage events. This file
// only ever stores/reads locally — the actual network calls live in
// platform_client.dart.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  AppPrefs._();

  static const _kQuickContact = 'quick_contact_number';
  static const _kRetentionDays = 'transcript_retention_days';
  static const _kAiConsent = 'ai_consent';
  static const _kAccessToken = 'platform_access_token';
  static const _kRefreshToken = 'platform_refresh_token';
  static const _kCachedProfileJson = 'platform_cached_profile_json';
  static const _kQueuedEventsJson = 'platform_queued_events_json';

  /// Default retention for saved transcripts (minimal by design).
  static const int defaultRetentionDays = 30;

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // ── Transcript retention (days) ─────────────────────────────────────────

  static Future<int> getRetentionDays() async {
    return (await _prefs).getInt(_kRetentionDays) ?? defaultRetentionDays;
  }

  static Future<void> setRetentionDays(int days) async {
    await (await _prefs).setInt(_kRetentionDays, days);
  }

  // ── AI consent (first-run) ──────────────────────────────────────────────

  /// Whether the student has consented to using the third-party AI services.
  /// Returns null if they have not been asked yet, true if accepted, false if
  /// declined.
  static Future<bool?> getAiConsent() async {
    return (await _prefs).getBool(_kAiConsent);
  }

  static Future<void> setAiConsent(bool accepted) async {
    await (await _prefs).setBool(_kAiConsent, accepted);
  }

  // ── Quick contact (اتصال سريع) ──────────────────────────────────────────

  /// The phone number the student chose for the quick-contact button, or null
  /// if they have not set one yet.
  static Future<String?> getQuickContactNumber() async {
    final value = (await _prefs).getString(_kQuickContact);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  static Future<void> setQuickContactNumber(String number) async {
    await (await _prefs).setString(_kQuickContact, number.trim());
  }

  static Future<void> clearQuickContactNumber() async {
    await (await _prefs).remove(_kQuickContact);
  }

  // ── Platform session (JWTs) ─────────────────────────────────────────────

  static Future<String?> getAccessToken() async =>
      (await _prefs).getString(_kAccessToken);

  static Future<void> setAccessToken(String token) async =>
      (await _prefs).setString(_kAccessToken, token);

  static Future<String?> getRefreshToken() async =>
      (await _prefs).getString(_kRefreshToken);

  static Future<void> setRefreshToken(String token) async =>
      (await _prefs).setString(_kRefreshToken, token);

  /// Clears the platform session (logout) — does NOT clear the cached
  /// profile/directives or queued events, so the app keeps working
  /// offline-first with the last-known-good state until the student logs
  /// back in.
  static Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
  }

  // ── Cached platform profile (offline-first) ─────────────────────────────

  /// Raw JSON string of the last successful GET /api/student/profile
  /// response (enabledTools + adaptationDirectives). Used whenever the
  /// platform is unreachable so a mode never blocks on a failed network call.
  static Future<String?> getCachedProfileJson() async =>
      (await _prefs).getString(_kCachedProfileJson);

  static Future<void> setCachedProfileJson(Map<String, dynamic> json) async =>
      (await _prefs).setString(_kCachedProfileJson, jsonEncode(json));

  // ── Queued usage events (offline-first outbox) ──────────────────────────

  /// Not-yet-sent usage events, as a raw JSON array string. Appended to
  /// while offline or between flush cycles; cleared once a batch upload to
  /// POST /api/events succeeds.
  static Future<List<Map<String, dynamic>>> getQueuedEvents() async {
    final raw = (await _prefs).getString(_kQueuedEventsJson);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setQueuedEvents(List<Map<String, dynamic>> events) async {
    await (await _prefs).setString(_kQueuedEventsJson, jsonEncode(events));
  }
}
