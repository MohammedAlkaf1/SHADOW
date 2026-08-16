import 'dart:math' as math;

import '/a11y.dart';
import '/pages/consent/consent_screen.dart';
import '/services/app_prefs.dart';
import '/services/mentor_triggers.dart';
import '/services/transcript_store.dart';
import '/student/student_profile.dart';
import '/student/student_profile_provider.dart';
import '/theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'welcome_selection_model.dart';
export 'welcome_selection_model.dart';

// Visual-only constants for this screen's redesign — deliberately local
// (not added to AppSpacing/theme.dart) so this pass touches only this file,
// per the request to leave every other screen untouched.
const double _kSectionGap = 28.0;
const double _kCardGap = 16.0;
const double _kCardRadius = 24.0;
const double _kEchoRadius = 24.0;

class WelcomeSelectionWidget extends StatefulWidget {
  const WelcomeSelectionWidget({super.key});

  static String routeName = 'WelcomeSelection';
  static String routePath = '/welcomeSelection';

  @override
  State<WelcomeSelectionWidget> createState() => _WelcomeSelectionWidgetState();
}

class _WelcomeSelectionWidgetState extends State<WelcomeSelectionWidget>
    with SingleTickerProviderStateMixin {
  late WelcomeSelectionModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // shfade: whole screen fades/slides in once on first build.
  late final AnimationController _entrance;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  // Real data where it actually exists: the timestamp of the most recent
  // saved deaf-mode transcript, shown as "آخر جلسة: <relative time>" on the
  // primary card. Null until loaded, or if the student has never saved one
  // — noSessionsYet covers both without inventing a fake session.
  DateTime? _lastSessionAt;
  bool _lastSessionLoaded = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WelcomeSelectionModel());
    timeago.setLocaleMessages('ar', timeago.ArMessages());

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _entranceFade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.015),
      end: Offset.zero,
    ).animate(_entranceFade);

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

    TranscriptStore.instance.listAll().then((transcripts) {
      if (!mounted) return;
      setState(() {
        _lastSessionAt = transcripts.isEmpty ? null : transcripts.first.createdAt;
        _lastSessionLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _model.dispose();
    super.dispose();
  }

  String get _greeting =>
      DateTime.now().hour < 12 ? 'home.greetingMorning'.tr() : 'home.greetingEvening'.tr();

  String get _lastSessionLabel {
    if (!_lastSessionLoaded) return '';
    final at = _lastSessionAt;
    if (at == null) return 'home.noSessionsYet'.tr();
    return 'home.lastSession'.tr(args: [timeago.format(at, locale: context.locale.languageCode)]);
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
        child: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: _kSectionGap),
                  _greetingBlock(),
                  const SizedBox(height: _kSectionGap),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isModeEnabled(profile, 'DEAF_MODE')) ...[
                            _primaryDeafCard(),
                            const SizedBox(height: _kCardGap + 10),
                          ],
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_isModeEnabled(profile, 'VISUAL_MODE'))
                                  Expanded(
                                    child: _secondaryCard(
                                      icon: Icons.remove_red_eye_rounded,
                                      title: 'modes.visual.title'.tr(),
                                      desc: 'modes.visual.desc'.tr(),
                                      onTap: () => context.pushNamed(
                                          VisualAssistanceModeWidget.routeName),
                                    ),
                                  ),
                                if (_isModeEnabled(profile, 'VISUAL_MODE') &&
                                    _isModeEnabled(profile, 'PHYSICAL_MODE'))
                                  const SizedBox(width: _kCardGap),
                                if (_isModeEnabled(profile, 'PHYSICAL_MODE'))
                                  Expanded(
                                    child: _secondaryCard(
                                      icon: Icons.graphic_eq_rounded,
                                      title: 'modes.physical.title'.tr(),
                                      desc: 'modes.physical.desc'.tr(),
                                      onTap: () => context.pushNamed(
                                          PhysicalAssistanceModeWidget.routeName),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_isModeEnabled(profile, 'LEARNING_MODE')) ...[
                            const SizedBox(height: _kCardGap),
                            _learningCard(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        // The Shadow logo — already carries its own navy gradient + rounded
        // corners (assets/icon/app_icon.png), so this Container only adds
        // the shadow and clips it to the spec's radius.
        Container(
          width: 48.0,
          height: 48.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: EchoColors.shadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/icon/app_icon.png'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text('app.title'.tr(), style: AppText.cardTitle(color: AppColors.onCream)),
        ),
        a11yButton(
          label: 'home.settings'.tr(),
          child: Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: EchoColors.shadow,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.settings_rounded, color: AppColors.mutedOnCream, size: 20),
              onPressed: () => context.pushNamed(SettingsScreen.routeName),
            ),
          ),
        ),
      ],
    );
  }

  /// The dynamic personal greeting — the biggest, most prominent text on
  /// the screen. Time-of-day only (no student name: nothing in the local
  /// profile or the platform session currently carries one), and the
  /// subtitle is the spec's own permitted generic fallback rather than a
  /// fabricated schedule line, since there's no real timetable data source
  /// yet to draw from.
  Widget _greetingBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_greeting,
            textAlign: TextAlign.start,
            style: AppText.custom(
                fontSize: 26, fontWeight: FontWeight.w800, height: 1.3, color: AppColors.onCream)),
        const SizedBox(height: AppSpacing.xs),
        Text('home.scheduleFallback'.tr(),
            textAlign: TextAlign.start, style: AppText.label()),
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

  /// The single "primary card" per the new design language: full width,
  /// an "echo" shadow-shape peeking out behind it, animated wave bars, and
  /// the one CTA button per screen. Deaf/hard-of-hearing is the primary
  /// mode on this screen — matches the source design and the app's own
  /// stated priority (its live-captioning mode is the most-used per the
  /// mentor-log event volume elsewhere in the app).
  Widget _primaryDeafCard() {
    return Padding(
      // Room for the echo layer's peek beyond the card's own bottom-end
      // edge so it doesn't get clipped by this widget's own bounds.
      padding: const EdgeInsetsDirectional.only(bottom: 10.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            top: 16.0,
            bottom: -10.0,
            start: 16.0,
            end: -8.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: EchoColors.echo,
                borderRadius: BorderRadius.circular(_kEchoRadius),
              ),
            ),
          ),
          a11yButton(
            child: _PrimaryCard(
              title: 'modes.deaf.title'.tr(),
              desc: 'modes.deaf.desc'.tr(),
              ctaLabel: 'home.startListening'.tr(),
              subLabel: _lastSessionLabel,
              onTap: () => context.pushNamed(DeafModeTranscriptionWidget.routeName),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secondaryCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return a11yButton(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: EchoColors.shadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(_kCardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 28.0, color: AppColors.navy),
                  const SizedBox(height: AppSpacing.sm),
                  Text(title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.custom(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: AppColors.onCream)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(desc,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.custom(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: AppColors.mutedOnCream)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _learningCard() {
    return a11yButton(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: EchoColors.shadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(_kCardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.pushNamed(LearningSupportModeWidget.routeName),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: EchoColors.iconTile,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.menu_book_rounded,
                        size: 20.0, color: EchoColors.iconGlyph),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('modes.learning.title'.tr(),
                            textAlign: TextAlign.start,
                            style: AppText.custom(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: AppColors.onCream)),
                        const SizedBox(height: AppSpacing.xs),
                        Text('modes.learning.desc'.tr(),
                            textAlign: TextAlign.start,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label()),
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

/// The primary card's content: title + animated wave bars, description,
/// then a row with the one CTA button per screen and the (real, when
/// available) last-session line. A gentle press scale/fade, matching the
/// rest of this screen's cards.
class _PrimaryCard extends StatefulWidget {
  const _PrimaryCard({
    required this.title,
    required this.desc,
    required this.ctaLabel,
    required this.subLabel,
    required this.onTap,
  });

  final String title;
  final String desc;
  final String ctaLabel;
  final String subLabel;
  final VoidCallback onTap;

  @override
  State<_PrimaryCard> createState() => _PrimaryCardState();
}

class _PrimaryCardState extends State<_PrimaryCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: EchoColors.primaryBg,
          borderRadius: BorderRadius.circular(_kCardRadius),
          boxShadow: EchoColors.primaryShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(_kCardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: _setPressed,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(widget.title,
                            textAlign: TextAlign.start,
                            style: AppText.custom(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                                color: EchoColors.primaryText)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const _WaveBars(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(widget.desc,
                      textAlign: TextAlign.start,
                      style: AppText.custom(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                          color: EchoColors.primarySub)),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.terracotta,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.terracotta.withValues(alpha: 0.35),
                              blurRadius: 16.0,
                              offset: const Offset(0, 6.0),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg, vertical: 14.0),
                          child: Text(widget.ctaLabel,
                              style: AppText.button(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(widget.subLabel,
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.custom(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                                color: EchoColors.primarySub)),
                      ),
                    ],
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

/// "shwave" — 4 looping bars (heights 55/100/75/45%), each phase-offset
/// slightly from the next so they don't move in lockstep. The tallest bar
/// is tinted terracotta — the one wave among the animation that stands
/// out, per the design brief's single-accent rule.
class _WaveBars extends StatefulWidget {
  const _WaveBars();

  @override
  State<_WaveBars> createState() => _WaveBarsState();
}

class _WaveBarsState extends State<_WaveBars> with SingleTickerProviderStateMixin {
  static const _heights = [0.55, 1.0, 0.75, 0.45];
  static const _maxBarHeight = 22.0;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _maxBarHeight,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_heights.length, (i) {
              final phase = i * 0.16;
              final wave = 0.5 +
                  0.5 * math.sin(2 * math.pi * (_controller.value + phase));
              final scale = 0.35 + 0.65 * wave;
              return Padding(
                padding: EdgeInsetsDirectional.only(start: i == 0 ? 0.0 : 3.0),
                child: Container(
                  width: 4.0,
                  height: _maxBarHeight * _heights[i] * scale,
                  decoration: BoxDecoration(
                    color: i == 1 ? AppColors.terracotta : EchoColors.primaryWave,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
