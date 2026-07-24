import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadow/services/app_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Fresh, empty prefs for each test (no real device storage).
    SharedPreferences.setMockInitialValues({});
  });

  group('AI consent', () {
    test('is null before the student is asked', () async {
      expect(await AppPrefs.getAiConsent(), isNull);
    });

    test('accept then read => true', () async {
      await AppPrefs.setAiConsent(true);
      expect(await AppPrefs.getAiConsent(), isTrue);
    });

    test('decline then read => false', () async {
      await AppPrefs.setAiConsent(false);
      expect(await AppPrefs.getAiConsent(), isFalse);
    });
  });

  group('Transcript retention', () {
    test('defaults to 30 days when unset', () async {
      expect(await AppPrefs.getRetentionDays(), 30);
      expect(AppPrefs.defaultRetentionDays, 30);
    });

    test('can be changed and persists', () async {
      await AppPrefs.setRetentionDays(7);
      expect(await AppPrefs.getRetentionDays(), 7);
    });
  });

  group('Quick contact number', () {
    test('is null when unset', () async {
      expect(await AppPrefs.getQuickContactNumber(), isNull);
    });

    test('is trimmed on save and read', () async {
      await AppPrefs.setQuickContactNumber('  0501234567  ');
      expect(await AppPrefs.getQuickContactNumber(), '0501234567');
    });

    test('blank is treated as unset', () async {
      await AppPrefs.setQuickContactNumber('   ');
      expect(await AppPrefs.getQuickContactNumber(), isNull);
    });
  });
}
