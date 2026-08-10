// App-wide settings screen. Currently holds only the language toggle
// (العربية / English) — the single choice that drives three things together:
// the UI language (via easy_localization's context.setLocale), the Deepgram
// transcription language, and which language version of the Gemini prompts
// is used (both of the latter read AppPrefs.getAppLanguage(), since they run
// from custom_code actions with no BuildContext).

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '/a11y.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/main.dart' show kSupportedLocales;
import '/services/app_prefs.dart';
import '/services/platform_client.dart';
import '/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static String routeName = 'Settings';
  static String routePath = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    PlatformClient.isLoggedIn.then((value) {
      if (mounted) setState(() => _loggedIn = value);
    });
  }

  Future<void> _selectLanguage(String languageCode) async {
    if (context.locale.languageCode == languageCode) return;
    // Keep the two sources in sync: easy_localization drives the UI
    // reactively; AppPrefs is what Deepgram/Gemini (no BuildContext) read.
    await context.setLocale(Locale(languageCode));
    await AppPrefs.setAppLanguage(languageCode);
    if (mounted) setState(() {});
  }

  /// The only way to end a platform session from inside the app — without
  /// this, a token stored by a previous login (this device, an earlier
  /// build) has no way to be cleared short of uninstalling, so the splash
  /// screen's "already logged in" check keeps skipping straight past the
  /// login screen indefinitely.
  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        title: Text('settings.signOutConfirmTitle'.tr(),
            textAlign: TextAlign.start, style: AppText.title()),
        content: Text('settings.signOutConfirmBody'.tr(),
            textAlign: TextAlign.start, style: AppText.body()),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common.cancel'.tr(),
                style: AppText.button(color: AppColors.navy)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: AppColors.onNavy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('settings.signOutAction'.tr(),
                style: AppText.button(color: AppColors.onNavy)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await PlatformClient.logout();
    if (!mounted) return;
    context.go(LoginWidget.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final current = context.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.onCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        leading: a11yButton(
          label: 'settings.back'.tr(),
          child: IconButton(
            icon: appBackIcon(context),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text('settings.title'.tr(), style: AppText.title()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('settings.language'.tr(),
              textAlign: TextAlign.start, style: AppText.cardTitle(color: AppColors.onCream)),
          const SizedBox(height: AppSpacing.xs),
          Text('settings.languageHint'.tr(),
              textAlign: TextAlign.start, style: AppText.caption()),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: AppDecor.creamCard(),
            child: Column(
              children: [
                for (final locale in kSupportedLocales)
                  _languageTile(
                    code: locale.languageCode,
                    label: locale.languageCode == 'ar'
                        ? 'settings.languageArabic'.tr()
                        : 'settings.languageEnglish'.tr(),
                    selected: current == locale.languageCode,
                  ),
              ],
            ),
          ),
          if (_loggedIn) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('settings.account'.tr(),
                textAlign: TextAlign.start,
                style: AppText.cardTitle(color: AppColors.onCream)),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: AppDecor.creamCard(),
              child: a11yButton(
                label: 'settings.signOut'.tr(),
                child: ListTile(
                  title: Text('settings.signOut'.tr(),
                      textAlign: TextAlign.start,
                      style: AppText.body(color: AppColors.terracotta)),
                  trailing:
                      const Icon(Icons.logout_rounded, color: AppColors.terracotta),
                  onTap: _confirmSignOut,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Bare RadioListTile (no a11yButton wrap): it already exposes correct
  // radio-button semantics on its own — matches the same choice made for
  // the Developer Tools profile-switch tiles.
  Widget _languageTile({
    required String code,
    required String label,
    required bool selected,
  }) {
    return RadioListTile<String>(
      value: code,
      // ignore: deprecated_member_use
      groupValue: context.locale.languageCode,
      activeColor: AppColors.terracotta,
      // ignore: deprecated_member_use
      onChanged: (v) {
        if (v != null) _selectLanguage(v);
      },
      title: Text(label, textAlign: TextAlign.start, style: AppText.body()),
    );
  }
}
