import '/a11y.dart';
import '/pages/consent/consent_screen.dart';
import '/services/app_prefs.dart';
import '/theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'welcome_selection_model.dart';
export 'welcome_selection_model.dart';

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
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
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
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'اختر نوع الدعم الذي تحتاجه',
                  textAlign: TextAlign.start,
                  style: AppText.label(),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _modeCard(
                                icon: Icons.hearing_rounded,
                                title: 'صمم / ضعف سمع',
                                desc: 'ترجمة فورية للمحاضرات',
                                route: DeafModeTranscriptionWidget.routeName,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _modeCard(
                                icon: Icons.visibility_rounded,
                                title: 'إعاقة بصرية',
                                desc: 'وصف المحيط والنصوص',
                                route: VisualAssistanceModeWidget.routeName,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _modeCard(
                                icon: Icons.menu_book_rounded,
                                title: 'صعوبات تعلم',
                                desc: 'تبسيط المواد الدراسية',
                                route: LearningSupportModeWidget.routeName,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _modeCard(
                                icon: Icons.record_voice_over_rounded,
                                title: 'إعاقة حركية',
                                desc: 'التحكم بالصوت',
                                route: PhysicalAssistanceModeWidget.routeName,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        // Brand mark — the single terracotta accent on this screen.
        Container(
          width: 52.0,
          height: 52.0,
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(14.0),
          ),
          alignment: Alignment.center,
          child: Text(
            'ش',
            style: GoogleFonts.tajawal(
              fontSize: 28.0,
              fontWeight: FontWeight.w900,
              color: AppColors.terracotta,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('شادو', style: AppText.display()),
              Text('مرافقك الأكاديمي الذكي', style: AppText.label()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeCard({
    required IconData icon,
    required String title,
    required String desc,
    required String route,
  }) {
    return a11yButton(
      child: Material(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.pushNamed(route),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 28.0, color: AppColors.navy),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle(),
                ),
                const SizedBox(height: AppSpacing.xs),
                Flexible(
                  child: Text(
                    desc,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(color: AppColors.mutedOnNavy),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('هل تحتاج إلى مساعدة؟ ', style: AppText.label()),
        Text(
          'تواصل معنا',
          style: AppText.label(color: AppColors.onCream)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
