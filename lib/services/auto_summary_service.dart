// Periodic "quiet" auto-summary for the deaf-mode live transcript
// (docs/شادو_خطة_التكيف_الشاملة.md — الوضع 1، دعم متوسط/مكثف).
//
// Deliberately isolated from the Deepgram/recording pipeline: this service
// only *reads* the latest transcript text via a callback the caller supplies
// and *reports* a summary back via another callback. It never touches
// FFAppState.liveText, the recording toggle, or any Deepgram/websocket code
// — so it cannot break the live transcription no matter what it does.
//
// Sentence counts (2 for moderate, 3 for intensive, short) are not specified
// in the plan doc's prose ("لخّص هذا في N جمل حسب المستوى" — N left open) —
// chosen to keep summaries skimmable without silencing the live transcript.

import 'dart:async';

import '/services/ai_client.dart';
import '/services/app_prefs.dart';
import '/student/student_profile.dart';

class AutoSummaryService {
  Timer? _pollTimer;
  DateTime? _lastSummaryAt;
  bool _busy = false;

  String Function()? _latestText;
  void Function(String summary)? _onSummary;

  bool get isActive => _pollTimer != null;

  /// Interval per support level. Light gets no periodic summary — the plan's
  /// table only defines one for moderate/intensive.
  static Duration? _intervalFor(SupportLevel level) => switch (level) {
        SupportLevel.light => null,
        SupportLevel.moderate => const Duration(minutes: 5),
        SupportLevel.intensive => const Duration(minutes: 2),
      };

  static int _sentenceCountFor(SupportLevel level) => switch (level) {
        SupportLevel.light => 2,
        SupportLevel.moderate => 2,
        SupportLevel.intensive => 3,
      };

  /// Starts polling. [latestText] is called on demand for the current live
  /// transcript; [onSummary] fires with each new summary. Safe to call
  /// repeatedly (restarts cleanly). A no-op tick occurs at light support —
  /// [_intervalFor] returns null there, so nothing is ever sent.
  ///
  /// Polls every 30s (rather than scheduling a single long-lived Duration)
  /// so a live support-level change — e.g. via the debug Developer Tools
  /// screen — changes the effective interval within 30s instead of only at
  /// whatever the *previous* level's next tick would have been.
  void start({
    required String Function() latestText,
    required void Function(String summary) onSummary,
  }) {
    stop();
    _latestText = latestText;
    _onSummary = onSummary;
    _lastSummaryAt = DateTime.now();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void _tick() {
    final interval = _intervalFor(StudentProfile.current.supportLevel);
    if (interval == null) return; // light: no periodic summary
    final lastAt = _lastSummaryAt;
    final due = lastAt == null || DateTime.now().difference(lastAt) >= interval;
    if (due) {
      _lastSummaryAt = DateTime.now();
      // Fire-and-forget: a tick is a background poll, nothing awaits it.
      // ignore: discarded_futures
      triggerNow();
    }
  }

  /// Runs a summary immediately regardless of schedule. Used by the
  /// intensive-only "لخّص لي الآن" button and by the internal poll tick.
  /// Silently no-ops if there's no text yet or a summary is already running.
  Future<void> triggerNow() async {
    if (_busy) return;
    final getText = _latestText;
    final onSummary = _onSummary;
    if (getText == null || onSummary == null) return;
    final text = getText().trim();
    if (text.isEmpty) return;

    // Silent guard for the unattended periodic-tick path (no BuildContext to
    // show a dialog from a Timer). The manual "لخّص لي الآن" button is
    // expected to call ensureAiConsent(context) itself before this — by then
    // consent is already true, so this is just a defensive backstop.
    if (await AppPrefs.getAiConsent() != true) return;

    _busy = true;
    try {
      final chunk =
          text.length > 800 ? text.substring(text.length - 800) : text;
      final sentences = _sentenceCountFor(StudentProfile.current.supportLevel);
      final result = await aiChatCompletion(
        maxTokens: 200,
        messages: [
          {
            'role': 'user',
            'content': 'لخّص هذا في $sentences جمل قصيرة جداً بالعربية:\n\n$chunk',
          },
        ],
      );
      if (result.ok) onSummary(result.content!);
    } finally {
      _busy = false;
    }
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _latestText = null;
    _onSummary = null;
  }

  void dispose() => stop();
}
