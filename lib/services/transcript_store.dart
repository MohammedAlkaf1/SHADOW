// Local, on-device store for saved lecture transcripts (sqflite).
//
// Privacy: transcripts never leave the device. There is no sync, no upload, no
// backend. Records auto-expire after a user-configurable retention period
// (see AppPrefs.getRetentionDays), and the student can delete any or all of them.

import 'package:sqflite/sqflite.dart';

class Transcript {
  Transcript({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  final int id;
  final String text;
  final DateTime createdAt;

  /// A short preview for lists (first line / first ~60 chars).
  String get preview {
    final firstLine = text.trim().split('\n').first;
    return firstLine.length <= 60 ? firstLine : '${firstLine.substring(0, 60)}…';
  }
}

class TranscriptStore {
  TranscriptStore._();
  static final TranscriptStore instance = TranscriptStore._();

  static const _dbName = 'shadow_transcripts.db';
  static const _table = 'transcripts';

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      '$dir/$_dbName',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  /// Saves a transcript. Returns its new id. Empty text is ignored (returns -1).
  Future<int> save(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return -1;
    final db = await _database;
    return db.insert(_table, {
      'text': trimmed,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// All transcripts, newest first.
  Future<List<Transcript>> listAll() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList();
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete(_table);
  }

  /// Deletes transcripts older than [retentionDays]. Returns how many were
  /// removed. Call on app/screen start to enforce the retention policy.
  Future<int> purgeExpired(int retentionDays) async {
    final db = await _database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    return db.delete(_table, where: 'created_at < ?', whereArgs: [cutoff]);
  }

  Transcript _fromRow(Map<String, Object?> row) => Transcript(
        id: row['id'] as int,
        text: row['text'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      );
}
