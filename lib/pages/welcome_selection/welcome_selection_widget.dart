import '/a11y.dart';
import '/pages/consent/consent_screen.dart';
import '/pages/deaf_mode_transcription/saved_transcripts_page.dart';
import '/pages/notifications/notifications_screen.dart';
import '/pages/voice_exam/voice_exam_list_widget.dart';
import '/services/app_prefs.dart';
import '/services/mentor_triggers.dart';
import '/theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'welcome_selection_model.dart';
export 'welcome_selection_model.dart';

// Visual-only constants for this screen's redesign — deliberately local
// (not added to AppSpacing/theme.dart) so this pass touches only this file,
// per the request to leave every other screen untouched. Values below are
// pulled 1:1 from the approved Figma file (rSY5pDmqY1jctcNOBg7gPC, node
// 37:56 "iPhone 15, 15 Pro").
const double _kHeroRadius = 24.0;
const double _kGridRadius = 20.0;
const double _kCardGap = 12.0; // gap between the two row-1 grid cards
const double _kHeroToGridGap = 20.0;
const double _kGridRowGap = 12.0; // row-1 grid -> row-2 wide card
const double _kGridToRecentGap = 20.0;
const double _kBottomNavHeight = 64.0;

/// A muted card tone distinct from [AppColors.surface] — used for the
/// grid/wide/recent cards in the Figma file (`#E7E1D5`), one step darker
/// than the header's icon-button surface (`#F5F1E9`).
const Color _kMutedCard = Color(0xFFE7E1D5);

/// The tab bar's own slightly-lighter-than-surface tone (`#FBF8F2`).
const Color _kTabBarBg = Color(0xFFFBF8F2);

/// The hero CTA button's label color (`#F7F3EC`) — close to but distinct
/// from [AppColors.onNavy].
const Color _kCtaTextColor = Color(0xFFF7F3EC);

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
  String? _savedEmail;

  // shfade: whole screen fades/slides in once on first build.
  late final AnimationController _entrance;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WelcomeSelectionModel());

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

    AppPrefs.getSavedCredentials().then((creds) {
      if (mounted && creds != null) setState(() => _savedEmail = creds.$1);
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _model.dispose();
    super.dispose();
  }

  void _openArchive() =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedTranscriptsPage()));

  void _openNotifications() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColors.cream,
      // The whole page — header, greeting, cards, footer — lives under one
      // outer scroll view instead of splitting a fixed header/footer from an
      // inner Expanded+SingleChildScrollView for just the cards. That split
      // meant the header/greeting sat outside any scrollable region, so a
      // larger accessibility text scale or a long greeting line had nowhere
      // to go but overflow (visible as the render-overflow stripes some
      // students reported as the cards "jiggling"). One scroll region for
      // the whole screen removes that failure mode entirely, and
      // ClampingScrollPhysics matches the platform's native (Android) scroll
      // feel rather than iOS-style overscroll bounce.
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  20.0, 12.0, 20.0, AppSpacing.xl + _kBottomNavHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: AppSpacing.lg),
                  _greeting(),
                  const SizedBox(height: AppSpacing.md),
                  _primaryDeafCard(),
                  const SizedBox(height: _kHeroToGridGap),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _secondaryCard(
                            icon: Icons.photo_camera_rounded,
                            title: 'home.serviceVisualTitle'.tr(),
                            onTap: () => context.pushNamed(
                                VisualAssistanceModeWidget.routeName),
                          ),
                        ),
                        const SizedBox(width: _kCardGap),
                        Expanded(
                          child: _secondaryCard(
                            icon: Icons.menu_book_rounded,
                            title: 'home.serviceLearningTitle'.tr(),
                            onTap: () => context.pushNamed(
                                LearningSupportModeWidget.routeName),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _kGridRowGap),
                  _wideCard(
                    icon: Icons.assignment_rounded,
                    title: 'home.servicePhysicalTitle'.tr(),
                    // Figma collapses the old single-button "physical mode"
                    // landing page and the exam list into one screen — go
                    // straight to the exam list, matching node 37:684.
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const VoiceExamListWidget())),
                  ),
                  const SizedBox(height: _kGridToRecentGap),
                  _recentSection(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header() {
    return Row(
      children: [
        // The Shadow wordmark — icon mark (assets/icon/shadow_wordmark_icon.png,
        // the approved orange-gradient fingerprint/wave mark) plus the
        // stacked "شادو" / "SHADOW" two-line lockup, exactly as in the
        // Figma header (node 37:105-37:112).
        SizedBox(
          width: 34.0,
          height: 34.0,
          child: Image.asset('assets/icon/shadow_wordmark_icon.png',
              fit: BoxFit.contain),
        ),
        const SizedBox(width: 10.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('app.title'.tr(),
                style: AppText.custom(
                    fontSize: 22, fontWeight: FontWeight.w800, height: 1.0, color: AppColors.onCream)),
            const SizedBox(height: 4.0),
            Text('app.brandEn'.tr(),
                style: AppText.custom(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    color: AppColors.terracotta,
                    letterSpacing: 4.5)),
          ],
        ),
        const Spacer(),
        a11yButton(
          label: 'home.notifications'.tr(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _headerCircleButton(
                icon: Icons.notifications_none_rounded,
                onTap: _openNotifications,
              ),
              PositionedDirectional(
                top: 9.0,
                end: 11.0,
                child: Container(
                  width: 9.0,
                  height: 9.0,
                  decoration: BoxDecoration(
                    color: AppColors.terracotta,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        a11yButton(
          label: 'home.profile'.tr(),
          child: _headerCircleButton(
            icon: Icons.person_rounded,
            onTap: () => context.pushNamed(SettingsScreen.routeName),
          ),
        ),
      ],
    );
  }

  /// Welcome line under the header, above the hero card — "Hello, {name}".
  /// The name has no real student-directory source, so it's derived from
  /// the remembered login email (same fallback pattern as the profile and
  /// settings screens); falls back to the app title if nothing is saved yet
  /// (e.g. first launch before AppPrefs.getSavedCredentials resolves).
  Widget _greeting() {
    final name = _savedEmail?.split('@').first ?? 'app.title'.tr();
    return Text('home.greeting'.tr(args: [name]),
        textAlign: TextAlign.start,
        style: AppText.custom(
            fontSize: 15, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.mutedOnCream));
  }

  Widget _headerCircleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 46.0,
      height: 46.0,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: EchoColors.shadow,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: AppColors.mutedOnCream, size: 21),
        onPressed: onTap,
      ),
    );
  }

  /// The hero card: full-width navy card, title + the one CTA button per
  /// screen. Deaf/hard-of-hearing is the primary mode on this screen —
  /// matches the source design and the app's own stated priority (its
  /// live-captioning mode is the most-used per the mentor-log event volume
  /// elsewhere in the app).
  Widget _primaryDeafCard() {
    return a11yButton(
      child: _PrimaryCard(
        title: 'deaf.title'.tr(),
        ctaLabel: 'home.startListening'.tr(),
        onTap: () => context.pushNamed(DeafModeTranscriptionWidget.routeName),
      ),
    );
  }

  /// Row-1 "quick access" card: icon tile top, title below, both right-
  /// aligned (no long description) — matches the Figma grid card exactly
  /// (icon-tile + title, `items-end`, no shadow).
  Widget _secondaryCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return a11yButton(
      child: Container(
        decoration: BoxDecoration(
          color: _kMutedCard,
          borderRadius: BorderRadius.circular(_kGridRadius),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(_kGridRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(17.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _gridIconTile(icon, size: 42.0, iconSize: 21.0),
                  const SizedBox(height: 18.0),
                  Text(title,
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.custom(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                          color: AppColors.onCream)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Row-2 wide card: icon tile at the visual left, title filling the rest,
  /// right-aligned — used for the physical-disability quick-access card.
  Widget _wideCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return a11yButton(
      child: Container(
        decoration: BoxDecoration(
          color: _kMutedCard,
          borderRadius: BorderRadius.circular(_kGridRadius),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(_kGridRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        textAlign: TextAlign.start,
                        style: AppText.custom(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                            color: AppColors.onCream)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _gridIconTile(icon, size: 38.0, iconSize: 20.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The small rounded icon square shared by the grid cards and the recent
  /// items list — cream-surface square with a rounded-2xl border. Defaults
  /// to a navy glyph (services grid); the recent-items list passes a
  /// softer, lighter glyph color to match Figma's muted document icons.
  Widget _gridIconTile(IconData icon,
      {required double size, required double iconSize, Color? iconColor}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size * 0.31),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: iconColor ?? AppColors.navy),
    );
  }

  /// "الأخيرة" — one big card (matches the Figma container exactly) holding
  /// the "عرض الكل" header row and the three recent-item rows. The items
  /// are static placeholder content: there is no backend source for
  /// "recent activity" yet, so this mirrors the design brief's literal
  /// sample content rather than fabricating a connection to real data.
  Widget _recentSection() {
    return Container(
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: _kMutedCard,
        borderRadius: BorderRadius.circular(_kGridRadius),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('home.recent'.tr(), style: AppText.title()),
              const Spacer(),
              a11yButton(
                label: 'home.viewAll'.tr(),
                child: InkWell(
                  onTap: _openArchive,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Text('home.viewAll'.tr(),
                        style: AppText.label(color: AppColors.terracotta)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _recentItem(
            title: 'home.recentChapterTitle'.tr(),
            tag: 'home.recentChapterTag'.tr(),
          ),
          const SizedBox(height: 4.0),
          _recentItem(
            title: 'home.recentSummaryTitle'.tr(),
            detail: 'home.recentSummaryDetail'.tr(),
            tag: 'home.recentSummaryTag'.tr(),
          ),
          const SizedBox(height: 4.0),
          _recentItem(
            title: 'home.recentReadingTitle'.tr(),
            detail: 'home.recentReadingDetail'.tr(),
            tag: 'home.recentReadingTag'.tr(),
          ),
        ],
      ),
    );
  }

  /// A single recent-activity row: title(+detail), a document-icon tile,
  /// then the type tag — plain (no background/shadow of its own), sitting
  /// directly inside the [_recentSection] card.
  Widget _recentItem({required String title, String? detail, required String tag}) {
    return a11yButton(
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(16.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openArchive,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.custom(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                              color: AppColors.onCream)),
                      if (detail != null) ...[
                        const SizedBox(height: 2.0),
                        Text(detail, textAlign: TextAlign.start, style: AppText.caption()),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _gridIconTile(Icons.description_rounded,
                    size: 42.0, iconSize: 20.0, iconColor: AppColors.mutedOnCream),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Text(tag,
                      style: AppText.caption(color: AppColors.mutedOnCream)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Floating capsule bottom nav — home / archive / account. Home routes
  /// nowhere (already on it); archive opens the saved-transcripts list
  /// (the closest existing screen to "المحفوظات"); account opens Settings
  /// (the closest existing screen to "الحساب") — neither a dedicated
  /// Archive nor Account screen exists yet.
  Widget _bottomNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, AppSpacing.sm),
        child: Container(
          height: _kBottomNavHeight,
          decoration: BoxDecoration(
            color: _kTabBarBg,
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
                active: true,
                onTap: () {},
              ),
              _navItem(
                icon: Icons.inventory_2_rounded,
                label: 'home.navArchive'.tr(),
                active: false,
                onTap: _openArchive,
              ),
              _navItem(
                icon: Icons.person_rounded,
                label: 'home.navAccount'.tr(),
                active: false,
                onTap: () => context.pushNamed(SettingsScreen.routeName),
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
    // Active tab: terracotta icon, navy-bold label — matches the Figma tab
    // bar exactly (the active label is navy, not terracotta).
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

/// The hero card's content: title, then the one CTA button per screen. A
/// gentle press scale/fade, matching the rest of this screen's cards.
class _PrimaryCard extends StatefulWidget {
  const _PrimaryCard({
    required this.title,
    required this.ctaLabel,
    required this.onTap,
  });

  final String title;
  final String ctaLabel;
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
          borderRadius: BorderRadius.circular(_kHeroRadius),
          boxShadow: EchoColors.primaryShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(_kHeroRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: _setPressed,
            child: Padding(
              padding: const EdgeInsets.all(20.8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.title,
                      textAlign: TextAlign.start,
                      style: AppText.custom(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                          color: EchoColors.primaryText)),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        constraints: const BoxConstraints(minHeight: 48.0),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta,
                          borderRadius: BorderRadius.circular(14.0),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.terracotta.withValues(alpha: 0.55),
                              blurRadius: 9.0,
                              offset: const Offset(0, 8.0),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Center(
                            child: Text(widget.ctaLabel,
                                style: AppText.button(color: _kCtaTextColor)),
                          ),
                        ),
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

