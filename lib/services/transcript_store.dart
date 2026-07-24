// Local, on-device store for saved lecture transcripts (sqflite).
//
// Privacy: transcripts never leave the device. There is no sync, no upload, no
// backend. Records auto-expire after a user-configurable retention period
// (see AppPrefs.getRetentionDays), and the student can delete any or all of them.

import 'package:flutter/foundation.dart';
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
  /// The app uses [instance]. Tests construct their own with an in-memory
  /// sqflite-ffi factory and path (databaseFactory/databasePath injected).
  TranscriptStore({DatabaseFactory? databaseFactory, String? databasePath})
      : _factory = databaseFactory,
        _path = databasePath;

  static final TranscriptStore instance = TranscriptStore();

  static const _dbName = 'shadow_transcripts.db';
  static const _table = 'transcripts';

  final DatabaseFactory? _factory;
  final String? _path;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    // Default to the platform factory (set by the sqflite plugin on device).
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
            text TEXT NOT NULL,
            created_at INTEGER NOT NULL
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

  /// Test-only: insert a transcript with an explicit timestamp, so retention/
  /// expiry can be exercised deterministically.
  @visibleForTesting
  Future<int> saveAt(String text, DateTime createdAt) async {
    final db = await _database;
    return db.insert(_table, {
      'text': text.trim(),
      'created_at': createdAt.millisecondsSinceEpoch,
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
