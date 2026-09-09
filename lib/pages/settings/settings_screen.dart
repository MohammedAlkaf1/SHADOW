// App-wide account/settings screen. Chrome (grouped cards, chevron rows,
// dark-mode toggle, bottom nav) matches the approved Figma file
// (rSY5pDmqY1jctcNOBg7gPC, node 37:670, "الحساب"). Figma's card shows a
// student name ("ريم") that has no real data source anywhere in this app
// (no name field exists on StudentProfile or from the platform login
// response) — the email line uses the real remembered-login email when
// available and falls back to a generic label instead of fabricating an
// identity. Real functionality (language switch, 3-way dark mode incl.
// "auto", font size, sign-out) is preserved behind the chevron rows Figma's
// mockup implies, rather than being dropped to match static image content.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '/a11y.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/main.dart' show kSupportedLocales;
import '/pages/deaf_mode_transcription/saved_transcripts_page.dart';
import '/pages/profile/profile_screen.dart';
import '/services/app_prefs.dart';
import '/services/platform_client.dart';
import '/theme.dart';

const double _kBottomNavHeight = 64.0;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static String routeName = 'Settings';
  static String routePath = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loggedIn = false;
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;
  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    PlatformClient.isLoggedIn.then((value) {
      if (mounted) setState(() => _loggedIn = value);
    });
    AppPrefs.getSavedEmail().then((email) {
      if (mounted && email != null) setState(() => _savedEmail = email);
    });
  }

  void _selectThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    setDarkModeSetting(context, mode); // persists + rebuilds MyApp
    setState(() => _themeMode = mode);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        title: Text('settings.signOutConfirmTitle'.tr(),
            textAlign: TextAlign.start, style: AppText.title()),
        content: Text('settings.signOutConfirmBody'.tr(),
            textAlign: TextAlign.start, style: AppText.body()),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common.cancel'.tr(), style: AppText.button(color: AppColors.navy)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: AppColors.onNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('settings.signOutAction'.tr(), style: AppText.button(color: AppColors.onNavy)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await PlatformClient.logout();
    if (!mounted) return;
    context.go(LoginWidget.routePath);
  }

  void _openBottomSheet(String title, Widget content) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppSpacing.pill),
                  ),
                ),
              ),
              Text(title, textAlign: TextAlign.start, style: AppText.title()),
              const SizedBox(height: AppSpacing.md),
              content,
            ],
          ),
        ),
      ),
    );
  }

  void _openLanguageSheet() {
    _openBottomSheet(
      'settings.uiLanguage'.tr(),
      StatefulBuilder(
        builder: (ctx, setSheetState) => _radioCard([
          for (final locale in kSupportedLocales)
            _RadioRowSpec(
              selected: context.locale.languageCode == locale.languageCode,
              label: locale.languageCode == 'ar'
                  ? 'settings.languageArabic'.tr()
                  : 'settings.languageEnglish'.tr(),
              onTap: () async {
                await _selectLanguage(locale.languageCode);
                setSheetState(() {});
              },
            ),
        ]),
      ),
    );
  }

  void _openDarkModeSheet() {
    _openBottomSheet(
      'settings.darkModeLabel'.tr(),
      StatefulBuilder(
        builder: (ctx, setSheetState) => _radioCard([
          _RadioRowSpec(
            selected: _themeMode == ThemeMode.system,
            label: 'settings.darkModeAuto'.tr(),
            onTap: () {
              _selectThemeMode(ThemeMode.system);
              setSheetState(() {});
            },
          ),
          _RadioRowSpec(
            selected: _themeMode == ThemeMode.light,
            label: 'settings.darkModeLight'.tr(),
            onTap: () {
              _selectThemeMode(ThemeMode.light);
              setSheetState(() {});
            },
          ),
          _RadioRowSpec(
            selected: _themeMode == ThemeMode.dark,
            label: 'settings.darkModeDark'.tr(),
            onTap: () {
              _selectThemeMode(ThemeMode.dark);
              setSheetState(() {});
            },
          ),
        ]),
      ),
    );
  }

  void _openFontSizeSheet() {
    _openBottomSheet(
      'common.fontSize'.tr(),
      StatefulBuilder(
        builder: (ctx, setSheetState) => Slider(
          activeColor: AppColors.terracotta,
          inactiveColor: AppColors.border,
          value: FFAppState().readingFontSize.clamp(14.0, 32.0),
          min: 14.0,
          max: 32.0,
          divisions: 9,
          label: '${FFAppState().readingFontSize.round()}',
          onChanged: (val) {
            setSheetState(() {});
            setState(() {});
            FFAppState().update(() {
              FFAppState().readingFontSize = val;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 8.0),
              child: Text('settings.account'.tr(),
                  textAlign: TextAlign.start,
                  style: AppText.custom(
                      fontSize: 24, fontWeight: FontWeight.w800, height: 1.35, color: AppColors.onCream)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    20.0, 8.0, 20.0, AppSpacing.xl + _kBottomNavHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel('settings.account'.tr()),
                    _card([
                      _chevronRow(
                        title: _savedEmail == null ? 'app.title'.tr() : _savedEmail!.split('@').first,
                        subtitle: _savedEmail,
                        subtitleColor: AppColors.terracotta,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      ),
                      _chevronRow(
                        title: 'settings.editProfile'.tr(),
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      ),
                    ]),
                    const SizedBox(height: 26.0),
                    _sectionLabel('settings.appearance'.tr()),
                    _card([
                      _toggleRow(
                        title: 'settings.darkModeLabel'.tr(),
                        value: _themeMode == ThemeMode.dark,
                        onChanged: (v) => _selectThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                        onTap: _openDarkModeSheet,
                      ),
                      _chevronRow(
                        title: 'common.fontSize'.tr(),
                        subtitle: 'settings.fontSizePoints'
                            .tr(args: ['${FFAppState().readingFontSize.round()}']),
                        onTap: _openFontSizeSheet,
                      ),
                    ]),
                    const SizedBox(height: 26.0),
                    _sectionLabel('settings.languageAndReading'.tr()),
                    _card([
                      _chevronRow(
                        title: 'settings.uiLanguage'.tr(),
                        subtitle: context.locale.languageCode == 'ar'
                            ? 'settings.languageArabic'.tr()
                            : 'settings.languageEnglish'.tr(),
                        onTap: _openLanguageSheet,
                      ),
                    ]),
                    const SizedBox(height: 26.0),
                    _sectionLabel('settings.permissions'.tr()),
                    _card([
                      _chevronRow(
                        title: 'settings.microphone'.tr(),
                        onTap: openAppSettings,
                      ),
                      _chevronRow(
                        title: 'settings.camera'.tr(),
                        onTap: openAppSettings,
                      ),
                    ]),
                    const SizedBox(height: 26.0),
                    _sectionLabel('settings.legal'.tr()),
                    _card([
                      _chevronRow(
                        title: 'settings.privacyPolicy'.tr(),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                      ),
                    ]),
                    if (_loggedIn) ...[
                      const SizedBox(height: 26.0),
                      _signOutRow(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4.0, 0, 4.0, 8.0),
        child: Text(text,
            textAlign: TextAlign.start,
            style: AppText.custom(
                fontSize: 12, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.mutedOnCream)),
      );

  /// The shared grouped-rows card: surface bg, border, rounded 18, overflow
  /// clipped, soft shadow, divider borders between rows.
  Widget _card(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: EchoColors.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Container(height: 0.8, color: const Color(0xFFE4DFD4)),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _radioCard(List<_RadioRowSpec> specs) => _card([for (final s in specs) _radioRow(s)]);

  Widget _radioRow(_RadioRowSpec spec) {
    return a11yButton(
      label: spec.label,
      child: InkWell(
        onTap: spec.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56.0),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _RingRadio(selected: spec.selected),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(spec.label,
                    textAlign: TextAlign.start,
                    style: AppText.custom(
                        fontSize: 16, fontWeight: FontWeight.w600, height: 1.3, color: AppColors.onCream)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chevronRow({
    required String title,
    String? subtitle,
    Color? subtitleColor,
    required VoidCallback onTap,
  }) {
    return a11yButton(
      label: subtitle == null ? title : '$title, $subtitle',
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              appForwardChevron(context, color: AppColors.mutedOnCream, size: 18.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.custom(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: AppColors.onCream)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2.0),
                      Text(subtitle,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.custom(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              color: subtitleColor ?? AppColors.mutedOnCream)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTap,
  }) {
    return a11yButton(
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: const Color(0xFFF7F3EC),
                activeTrackColor: AppColors.terracotta,
                inactiveThumbColor: const Color(0xFFF7F3EC),
                inactiveTrackColor: AppColors.border,
              ),
              Expanded(
                child: Text(title,
                    textAlign: TextAlign.start,
                    style: AppText.custom(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: AppColors.onCream)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signOutRow() {
    return a11yButton(
      label: 'settings.signOut'.tr(),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: AppColors.terracotta, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _confirmSignOut,
            child: Container(
              constraints: const BoxConstraints(minHeight: 58.0),
              padding: const EdgeInsets.symmetric(horizontal: 18.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('settings.signOut'.tr(),
                      textAlign: TextAlign.start,
                      style: AppText.custom(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: AppColors.terracotta)),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.logout_rounded, color: AppColors.terracotta, size: 19.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, AppSpacing.sm),
        child: Container(
          height: _kBottomNavHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8F2),
            borderRadius: BorderRadius.circular(32.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.34),
                blurRadius: 17.0,
                offset: const Offset(0, 14.0),
              ),
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.09),
                blurRadius: 3.0,
                offset: const Offset(0, 2.0),
              ),
            ],
          ),
          child: Row(
            children: [
              _navItem(
                icon: Icons.home_rounded,
                label: 'home.navHome'.tr(),
                active: false,
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
              _navItem(
                icon: Icons.inventory_2_rounded,
                label: 'home.navArchive'.tr(),
                active: false,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const SavedTranscriptsPage())),
              ),
              _navItem(
                icon: Icons.person_rounded,
                label: 'home.navAccount'.tr(),
                active: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final iconColor = active ? AppColors.terracotta : AppColors.mutedOnCream;
    final labelColor = active ? AppColors.onCream : AppColors.mutedOnCream;
    return Expanded(
      child: a11yButton(
        label: label,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22.0, color: iconColor),
                const SizedBox(height: 2.0),
                Text(label,
                    style: AppText.caption(color: labelColor)
                        .copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioRowSpec {
  const _RadioRowSpec({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
}

/// Custom 22x22 ring-radio: terracotta ring + filled dot when selected,
/// muted ring + transparent center otherwise — the prototype's radio glyph
/// (replaces the platform RadioListTile look with the new design language,
/// while the actual selection state/logic above is unchanged).
class _RingRadio extends StatelessWidget {
  const _RingRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22.0,
      height: 22.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.terracotta : AppColors.mutedOnCream,
          width: 2.0,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 11.0,
              height: 11.0,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.terracotta),
            )
          : null,
    );
  }
}
