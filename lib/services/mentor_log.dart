// Local, structured event log for the future advisor (مرشد) alerting system
// (docs/شادو_خطة_التكيف_الشاملة.md, Phase 5 — "تنبيهات المرشد").
//
// The platform/backend does not exist yet. This is local-only storage: events
// are written on-device (sqflite, same library as transcript_store.dart) and
// queued for later sync. Nothing here uploads, notifies, or shows the student
// anything — see the "silent to the student" note on MentorLog.log().
//
// PDPL note: once these events carry a real student identifier (once the
// platform exists), this becomes health-adjacent data about a person with a
// disability — sensitive personal data under PDPL. Today every row is
// anonymous (no user id at all), so this file is safe as-is. The upload
// question needs a legal review before it is ever implemented — see the
// TODO(pdpl-review) markers at the two functions that would feed a future
// upload (unsyncedEvents / markSynced).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '/student/student_profile.dart';

/// What kind of usage pattern the event describes.
///
/// NOTE: [highFrequencyUse] is declared (per the plan's requested enum) but
/// has no described trigger condition anywhere in the plan's "المُشغّلات"
/// section — it is intentionally unwired. See the Phase 5 report for why.
enum EventType {
  repeatedRequest,
  sameFileMultipleTimes,
  rapidQuickContact,
  missedLectures,
  midSessionAbort,
  highFrequencyUse,
  weeklyReport,
}

/// How urgently a mentor should see this event, independent of which support
/// level triggered it: [info] = passive stat, [weekly] = goes in the weekly
/// digest, [immediate] = should surface right away once the platform exists.
enum EventSeverity {
  info,
  weekly,
  immediate,
}

class MentorEvent {
  MentorEvent({
    required this.id,
    required this.timestamp,
    required this.mode,
    required this.eventType,
    required this.severity,
    required this.details,
    required this.studentCategory,
    required this.supportLevel,
    required this.synced,
  });

  final int id;
  final DateTime timestamp;
  final String mode;
  final EventType eventType;
  final EventSeverity severity;
  final Map<String, dynamic> details;
  final StudentCategory studentCategory;
  final SupportLevel supportLevel;
  final bool synced;
}

class MentorLog {
  MentorLog({DatabaseFactory? databaseFactory, String? databasePath})
      : _factory = databaseFactory,
        _path = databasePath;

  static final MentorLog instance = MentorLog();

  static const _dbName = 'shadow_mentor_log.db';
  static const _table = 'mentor_events';

  /// Local storage cap — this is a testing/dev-time device, not a server, so
  /// bound it defensively and drop the oldest rows past this count.
  static const maxLocalEvents = 10000;

  final DatabaseFactory? _factory;
  final String? _path;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final factory = _factory ?? databaseFactory;
    final path = _path ?? '${await getDatabasesPath()}/$_dbName';
    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            mode TEXT NOT NULL,
            event_type TEXT NOT NULL,
            severity TEXT NOT NULL,
            details TEXT NOT NULL,
            category TEXT NOT NULL,
            support_level TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        },
      ),
    );
    return _db!;
  }

  /// Closes the underlying database (used by tests for isolation).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Records one event. Silent to the student — no snackbar, no sound, no
  /// visual hint anywhere; this only ever writes a local row. [category] and
  /// [supportLevel] are captured from [StudentProfile.current] at logging
  /// time (not passed in), matching every other adaptive call site in the
  /// app. Enforces [maxLocalEvents] by dropping the oldest rows past the cap.
  Future<int> log({
    required String mode,
    required EventType eventType,
    required EventSeverity severity,
    Map<String, dynamic> details = const {},
  }) async {
    final db = await _database;
    final profile = StudentProfile.current;
    final id = await db.insert(_table, {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'mode': mode,
      'event_type': eventType.name,
      'severity': severity.name,
      'details': jsonEncode(details),
      'category': profile.category.name,
      'support_level': profile.supportLevel.name,
      'synced': 0,
    });
    await _enforceCap(db);
    return id;
  }

  Future<void> _enforceCap(Database db) async {
    final countRow = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    final count = Sqflite.firstIntValue(countRow) ?? 0;
    final overflow = count - maxLocalEvents;
    if (overflow <= 0) return;
    // Delete the oldest `overflow` rows.
    await db.rawDelete('''
      DELETE FROM $_table WHERE id IN (
        SELECT id FROM $_table ORDER BY timestamp ASC LIMIT ?
      )
    ''', [overflow]);
  }

  /// Most recent events, newest first — used by the debug Developer Tools
  /// screen. [severity] filters to one severity when provided.
  Future<List<MentorEvent>> recent({
    int limit = 50,
    EventSeverity? severity,
  }) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: severity != null ? 'severity = ?' : null,
      whereArgs: severity != null ? [severity.name] : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Future<int> count() async {
    final db = await _database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Events not yet uploaded to the (not-yet-built) platform.
  //
  // TODO(pdpl-review): before this is ever wired to a network call, get legal
  // sign-off. These rows are anonymous today (no student id), but once a real
  // id is attached this becomes health-adjacent data about a person with a
  // disability — sensitive personal data under PDPL.
  Future<List<MentorEvent>> unsyncedEvents({int limit = 500}) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'synced = 0',
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  /// Marks the given event ids as synced, once a future upload succeeds.
  //
  // TODO(pdpl-review): same PDPL review requirement as unsyncedEvents() above
  // — this is the other half of the same not-yet-built upload path.
  Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE $_table SET synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  /// Deletes every local event — the debug Developer Tools "امسح كل الأحداث"
  /// button. Not reachable by the student.
  Future<void> clearAll() async {
    final db = await _database;
    await db.delete(_table);
  }

  MentorEvent _fromRow(Map<String, Object?> row) {
    Map<String, dynamic> details;
    try {
      details = jsonDecode(row['details'] as String) as Map<String, dynamic>;
    } catch (_) {
      details = const {};
    }
    return MentorEvent(
      id: row['id'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      mode: row['mode'] as String,
      eventType: _eventTypeFromName(row['event_type'] as String),
      severity: _severityFromName(row['severity'] as String),
      details: details,
      studentCategory: StudentCategoryParsing.fromName(row['category'] as String) ??
          StudentProfile.defaultProfile.category,
      supportLevel:
          SupportLevelParsing.fromName(row['support_level'] as String) ??
              StudentProfile.defaultProfile.supportLevel,
      synced: (row['synced'] as int) == 1,
    );
  }

  static EventType _eventTypeFromName(String name) {
    for (final value in EventType.values) {
      if (value.name == name) return value;
    }
    debugPrint('⚠️ MentorLog: unknown event_type "$name", defaulting');
    return EventType.highFrequencyUse;
  }

  static EventSeverity _severityFromName(String name) {
    for (final value in EventSeverity.values) {
      if (value.name == name) return value;
    }
    debugPrint('⚠️ MentorLog: unknown severity "$name", defaulting');
    return EventSeverity.info;
  }
}
