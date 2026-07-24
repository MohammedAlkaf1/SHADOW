import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shadow/services/transcript_store.dart';

void main() {
  // Run sqflite on the desktop VM (no device) with an in-memory database.
  sqfliteFfiInit();

  late TranscriptStore store;

  setUp(() {
    store = TranscriptStore(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await store.close();
  });

  test('save then list returns the transcript', () async {
    await store.save('محاضرة اليوم');
    final all = await store.listAll();
    expect(all, hasLength(1));
    expect(all.first.text, 'محاضرة اليوم');
  });

  test('empty text is not saved (returns -1)', () async {
    final id = await store.save('   ');
    expect(id, -1);
    expect(await store.listAll(), isEmpty);
  });

  test('list is newest-first', () async {
    await store.saveAt('older', DateTime(2026, 1, 1));
    await store.saveAt('newer', DateTime(2026, 6, 1));
    final all = await store.listAll();
    expect(all.map((t) => t.text).toList(), ['newer', 'older']);
  });

  test('delete removes a single transcript', () async {
    final id = await store.save('a');
    await store.save('b');
    await store.delete(id);
    final all = await store.listAll();
    expect(all, hasLength(1));
    expect(all.first.text, 'b');
  });

  test('deleteAll clears everything', () async {
    await store.save('a');
    await store.save('b');
    await store.deleteAll();
    expect(await store.listAll(), isEmpty);
  });

  group('30-day retention / auto-expiry', () {
    test('purges records older than the retention window, keeps fresh ones',
        () async {
      final now = DateTime.now();
      await store.saveAt('old lecture', now.subtract(const Duration(days: 40)));
      await store.saveAt('recent lecture', now.subtract(const Duration(days: 3)));

      final removed = await store.purgeExpired(30);

      expect(removed, 1);
      final all = await store.listAll();
      expect(all, hasLength(1));
      expect(all.first.text, 'recent lecture');
    });

    test('nothing purged when all records are within the window', () async {
      await store.saveAt('a', DateTime.now().subtract(const Duration(days: 10)));
      final removed = await store.purgeExpired(30);
      expect(removed, 0);
      expect(await store.listAll(), hasLength(1));
    });

    test('a shorter retention removes more', () async {
      final now = DateTime.now();
      await store.saveAt('8 days old', now.subtract(const Duration(days: 8)));
      expect(await store.purgeExpired(30), 0); // safe under 30
      expect(await store.purgeExpired(7), 1); // expired under 7
      expect(await store.listAll(), isEmpty);
    });
  });

  test('preview truncates long text to a single short line', () {
    final t = Transcript(
      id: 1,
      text: 'A' * 200,
      createdAt: DateTime.now(),
    );
    expect(t.preview.length, lessThanOrEqualTo(61)); // 60 chars + ellipsis
    expect(t.preview.endsWith('…'), isTrue);
  });
}
