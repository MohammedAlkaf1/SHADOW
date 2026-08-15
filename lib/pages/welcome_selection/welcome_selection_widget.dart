import '/a11y.dart';
import '/pages/consent/consent_screen.dart';
import '/services/app_prefs.dart';
import '/services/mentor_triggers.dart';
import '/student/student_profile.dart';
import '/student/student_profile_provider.dart';
import '/theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'welcome_selection_model.dart';
export 'welcome_selection_model.dart';

// Visual-only constants for this screen's redesign — deliberately local
// (not added to AppSpacing/theme.dart) so this pass touches only this file,
// per the request to leave every other screen untouched. Larger than the
// shared AppSpacing values on purpose, for the requested "more whitespace,
// clearer hierarchy" feel.
const double _kSectionGap = 36.0;
const double _kLabelToGridGap = 22.0;
const double _kCardGap = 18.0;
const double _kCardRadius = 24.0;

/// Soft, theme-aware card shadow. Both layers key off [AppColors.brightness]
/// (already the single source of truth main.dart keeps in sync with
/// ThemeMode) rather than a fixed color, so dark mode gets a visibly deeper
/// shadow instead of an invisible black-on-black one.
List<BoxShadow> _softShadow({double strength = 1.0}) {
  final dark = AppColors.brightness == Brightness.dark;
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: (dark ? 0.45 : 0.10) * strength),
      blurRadius: 24.0 * strength,
      offset: Offset(0, 10.0 * strength),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: (dark ? 0.25 : 0.05) * strength),
      blurRadius: 6.0 * strength,
      offset: Offset(0, 2.0 * strength),
    ),
  ];
}

class WelcomeSelectionWidget extends StatefulWidget {
  const WelcomeSelectionWidget({super.key});

  static String routeName = 'WelcomeSelection';
  static String routePath = '/welcomeSelection';

  @override
  State<WelcomeSelectionWidget> createState() => _WelcomeSelectionWidgetState();
}

class _WelcomeSelectionWidgetState extends State<WelcomeSelectionWidget> {
  late WelcomeSelectionModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WelcomeSelectionModel());
    // First run: show the AI privacy consent once.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final consent = await AppPrefs.getAiConsent();
      if (consent == null && mounted) {
        await showAiConsent(context);
      }
    });
    // Silent: weekly usage report + 14-day missed-lectures check
    // (moderate/intensive only). Never shown to the student.
    MentorTriggers.onAppOpen();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the platform-fetched profile/directives change (login,
    // or a background profile refresh) so mode gating stays live.
    context.watch<StudentProfileProvider>();
    final profile = StudentProfile.current;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: _kSectionGap),
              Text(
                'home.chooseSupport'.tr(),
                textAlign: TextAlign.start,
                style: AppText.label(),
              ),
              const SizedBox(height: _kLabelToGridGap),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _isModeEnabled(profile, 'DEAF_MODE')
                                ? _modeCard(
                                    icon: Icons.hearing_rounded,
                                    title: 'modes.deaf.title'.tr(),
                                    desc: 'modes.deaf.desc'.tr(),
                                    route:
                                        DeafModeTranscriptionWidget.routeName,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: _kCardGap),
                          Expanded(
                            child: _isModeEnabled(profile, 'VISUAL_MODE')
                                ? _modeCard(
                                    icon: Icons.visibility_rounded,
                                    title: 'modes.visual.title'.tr(),
                                    desc: 'modes.visual.desc'.tr(),
                                    route:
                                        VisualAssistanceModeWidget.routeName,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: _kCardGap),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _isModeEnabled(profile, 'LEARNING_MODE')
                                ? _modeCard(
                                    icon: Icons.menu_book_rounded,
                                    title: 'modes.learning.title'.tr(),
                                    desc: 'modes.learning.desc'.tr(),
                                    route:
                                        LearningSupportModeWidget.routeName,
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: _kCardGap),
                          Expanded(
                            child: _isModeEnabled(profile, 'PHYSICAL_MODE')
                                ? _modeCard(
                                    icon: Icons.record_voice_over_rounded,
                                    title: 'modes.physical.title'.tr(),
                                    desc: 'modes.physical.desc'.tr(),
                                    route: PhysicalAssistanceModeWidget
                                        .routeName,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        // Brand mark — the single terracotta accent on this screen. A subtle
        // diagonal gradient (navy -> navyDark, both already brightness-aware)
        // plus a soft shadow give it depth instead of a flat fill.
        Container(
          width: 56.0,
          height: 56.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navy, AppColors.navyDark],
            ),
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: _softShadow(strength: 0.7),
          ),
          alignment: Alignment.center,
          child: Text(
            'ش',
            style: AppText.custom(
              fontSize: 28.0,
              fontWeight: FontWeight.w900,
              color: AppColors.terracotta,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('app.title'.tr(), style: AppText.display()),
              Text('app.tagline'.tr(), style: AppText.label()),
            ],
          ),
        ),
        a11yButton(
          label: 'home.settings'.tr(),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: _softShadow(strength: 0.4),
            ),
            child: IconButton(
              icon: Icon(Icons.settings_rounded,
                  color: AppColors.mutedOnCream),
              onPressed: () => context.pushNamed(SettingsScreen.routeName),
            ),
          ),
        ),
      ],
    );
  }

  /// A mode's card only hides once we actually have a platform-fetched
  /// profile to gate against (`isPlatformLinked`) — before login, offline
  /// with nothing cached yet, or in dev-tools/demo mode, every mode stays
  /// visible (fail-open), matching this screen's original behavior.
  bool _isModeEnabled(StudentProfile profile, String toolCode) {
    if (!profile.isPlatformLinked) return true;
    return profile.enabledTools.contains(toolCode);
  }

  Widget _modeCard({
    required IconData icon,
    required String title,
    required String desc,
    required String route,
  }) {
    return a11yButton(
      child: _ModeCard(
        icon: icon,
        title: title,
        desc: desc,
        onTap: () => context.pushNamed(route),
      ),
    );
  }

  Widget _footer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('home.needHelp'.tr(), style: AppText.label()),
            Text(
              'home.contactUs'.tr(),
              style: AppText.label(color: AppColors.onCream)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        // Debug-only entry point to the adaptation-engine test screen.
        // kDebugMode is false in release/profile builds, so this never
        // ships to students.
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.sm),
          a11yButton(
            label: 'home.devTools'.tr(),
            child: TextButton.icon(
              onPressed: () => context.pushNamed(DevToolsPage.routeName),
              icon: Icon(Icons.science_outlined,
                  size: 16, color: AppColors.mutedOnCream),
              label: Text('home.devTools'.tr(),
                  style: AppText.label().copyWith(
                      decoration: TextDecoration.underline)),
            ),
          ),
        ],
      ],
    );
  }
}

/// A mode-selection card: soft-shadowed, subtly gradient-filled, with a
/// large low-opacity "ghost" copy of its own icon watermarked in the corner
/// (a lightweight duotone-style effect that needs no new icon assets) and a
/// gentle scale/fade on press. Purely presentational — [onTap] is the exact
/// same route-push the plain card used to call directly, and every
/// interactive/announced element is still whatever [a11yButton] wraps this
/// in at the call site.
class _ModeCard extends StatefulWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navy, AppColors.navyDark],
            ),
            borderRadius: BorderRadius.circular(_kCardRadius),
            boxShadow: _softShadow(),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(_kCardRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _setPressed,
              child: Stack(
                children: [
                  // Faux-duotone watermark: a large, near-invisible copy of
                  // the same icon peeking from the corner. Decorative only —
                  // excluded from the semantics tree so TalkBack never
                  // announces a second, unlabelled icon.
                  Positioned(
                    right: -14.0,
                    bottom: -14.0,
                    child: ExcludeSemantics(
                      child: Icon(
                        widget.icon,
                        size: 108.0,
                        color: AppColors.onNavy.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64.0,
                          height: 64.0,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.surface,
                                Color.lerp(
                                    AppColors.surface, AppColors.navy, 0.06)!,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: _softShadow(strength: 0.5),
                          ),
                          alignment: Alignment.center,
                          // onCream (not navy) so the icon still reads
                          // clearly against this circle in dark mode, where
                          // navy and surface are both very dark and would
                          // otherwise sit almost on top of each other.
                          child: Icon(widget.icon,
                              size: 30.0, color: AppColors.onCream),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.cardTitle(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            widget.desc,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label(color: AppColors.mutedOnNavy),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
