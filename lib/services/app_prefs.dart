// Local, on-device settings backed by shared_preferences.
//
// Nothing here leaves the device. Used for the quick-contact number, the
// first-run consent flag, and transcript retention. No accounts, no backend.

import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  AppPrefs._();

  static const _kQuickContact = 'quick_contact_number';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

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
}
