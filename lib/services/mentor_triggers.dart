// Wires the mentor-log triggers described in
// docs/شادو_خطة_التكيف_الشاملة.md (Phase 5) that fire on app open: the
// moderate+ weekly usage report, and the moderate+ "missed lectures" (14-day
// no-open) alert. Per-mode intensive triggers (repeatedRequest,
// sameFileMultipleTimes, rapidQuickContact, midSessionAbort) live next to the
// mode code that can actually observe them — see the Phase 5 report for why.
//
// Entirely silent to the student — this only ever writes to MentorLog.

import 'package:shared_preferences/shared_preferences.dart';

import '/services/mentor_log.dart';
import '/student/student_profile.dart';

class MentorTriggers {
  MentorTriggers._();

  static const _kLastAppOpen = 'mentor_last_app_open';
  static const _kLastWeeklyReport = 'mentor_last_weekly_report';
  static const _kModeOpenCountPrefix = 'mentor_mode_open_count_';
  static const _kQuickContactDate = 'mentor_quick_contact_date';
  static const _kQuickContactCount = 'mentor_quick_contact_count';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  /// Call once per app open (welcome/home screen initState). Silent —
  /// no UI, no student-visible effect. No-op below moderate support.
  static Future<void> onAppOpen() async {
    final profile = StudentProfile.current;
    if (!profile.isAtLeast(SupportLevel.moderate)) return;

    final prefs = await _prefs;
    final now = DateTime.now();

    final lastOpenMs = prefs.getInt(_kLastAppOpen);
    if (lastOpenMs != null) {
      final gap = now.difference(DateTime.fromMillisecondsSinceEpoch(lastOpenMs));
      if (gap.inDays >= 14) {
        await MentorLog.instance.log(
          mode: 'app',
          eventType: EventType.missedLectures,
          severity: EventSeverity.immediate,
          details: {'days_since_last_open': gap.inDays},
        );
      }
    }
    await prefs.setInt(_kLastAppOpen, now.millisecondsSinceEpoch);

    final lastReportMs = prefs.getInt(_kLastWeeklyReport);
    final dueForReport = lastReportMs == null ||
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastReportMs)).inDays >= 7;
    if (dueForReport) {
      final snapshot = await _snapshotAndResetModeOpens(prefs);
      await MentorLog.instance.log(
        mode: 'app',
        eventType: EventType.weeklyReport,
        severity: EventSeverity.weekly,
        details: {'mode_opens': snapshot},
      );
      await prefs.setInt(_kLastWeeklyReport, now.millisecondsSinceEpoch);
    }
  }

  /// Call from a mode screen's initState to count it toward the weekly
  /// usage report (e.g. "الأوضاع الأكثر استخداماً").
  static Future<void> incrementModeOpen(String mode) async {
    final prefs = await _prefs;
    final key = '$_kModeOpenCountPrefix$mode';
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }

  /// rapidQuickContact (intensive only): call each time the quick-contact
  /// number is actually dialed. Logs once per day, the first time that
  /// day's count reaches 2 — not once per call — so a busy day doesn't spam
  /// the log with a duplicate event on every subsequent dial.
  static Future<void> recordQuickContactUse() async {
    if (!StudentProfile.current.isIntensive) return;
    final prefs = await _prefs;
    final today = _dateKey(DateTime.now());
    final storedDate = prefs.getString(_kQuickContactDate);
    var count =
        (storedDate == today) ? (prefs.getInt(_kQuickContactCount) ?? 0) : 0;
    count++;
    await prefs.setString(_kQuickContactDate, today);
    await prefs.setInt(_kQuickContactCount, count);
    if (count == 2) {
      await MentorLog.instance.log(
        mode: 'physical',
        eventType: EventType.rapidQuickContact,
        severity: EventSeverity.immediate,
        details: {'count_today': count},
      );
    }
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static Future<Map<String, int>> _snapshotAndResetModeOpens(
      SharedPreferences prefs) async {
    const modes = ['deaf', 'visual', 'learning', 'physical'];
    final snapshot = <String, int>{};
    for (final mode in modes) {
      final key = '$_kModeOpenCountPrefix$mode';
      snapshot[mode] = prefs.getInt(key) ?? 0;
      await prefs.remove(key);
    }
    return snapshot;
  }
}
