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

/// The one navy gradient used everywhere on this screen that needs depth
/// (the "ش" brand mark and all four mode cards) — a visibly lighter navy on
/// top settling into a visibly darker one at the bottom. Fixed hex values
/// rather than the AppColors.navy/navyDark tokens: those two are close
/// enough in lightness (0x1E2A3A vs 0x16202C) that the gradient between them
/// barely read on-device; this pair has a wide enough gap to actually show.
/// Both stops are dark navy regardless of theme, so the same pair reads
/// correctly whether the card sits on the light cream page or the dark one.
const List<Color> _kNavyGradient = [Color(0xFF25384C), Color(0xFF182231)];

/// Card-level drop shadow — separates each card from the cream/dark page
/// background behind it. Alpha stays in the light 0.08-0.12 range in light
/// mode as specced; boosted in dark mode so it doesn't vanish against an
/// already-dark background.
List<BoxShadow> _cardShadow() {
  final dark = AppColors.brightness == Brightness.dark;
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.40 : 0.10),
      blurRadius: 22.0,
      offset: const Offset(0, 8.0),
    ),
  ];
}

/// Lighter shadow for smaller raised elements (the icon circle, the brand
/// mark, the settings button) — same idea, less of it.
List<BoxShadow> _smallShadow() {
  final dark = AppColors.brightness == Brightness.dark;
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.35 : 0.15),
      blurRadius: 8.0,
      offset: const Offset(0, 3.0),
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
        // Brand mark — the designed Shadow logo (assets/icon/app_icon.png,
        // the same source used to generate the launcher icon). It already
        // carries its own navy gradient + rounded corners, so this
        // Container only adds the shadow.
        Container(
          width: 56.0,
          height: 56.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: _smallShadow(),
          ),
          child: Image.asset('assets/icon/app_icon.png'),
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
              boxShadow: _smallShadow(),
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
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _kNavyGradient,
            ),
            borderRadius: BorderRadius.circular(_kCardRadius),
            boxShadow: _cardShadow(),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(_kCardRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _setPressed,
              child: Padding(
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
                        boxShadow: _smallShadow(),
                      ),
                      alignment: Alignment.center,
                      // onCream (not navy) so the icon still reads clearly
                      // against this circle in dark mode, where navy and
                      // surface are both very dark and would otherwise sit
                      // almost on top of each other.
                      child: Icon(widget.icon,
                          size: 30.0, color: AppColors.onCream),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Pure white + bold for the title, a warm light grey for
                    // the description below it — a deliberately wider
                    // contrast gap than AppColors.onNavy/mutedOnNavy gave,
                    // so primary vs. secondary is unmistakable at a glance.
                    // Both fixed (not brightness-derived): the card itself
                    // stays this same dark navy gradient in both themes, so
                    // there's no dark-mode variant these need to switch to.
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        widget.desc,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                            color: const Color(0xFFB8BFC7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
