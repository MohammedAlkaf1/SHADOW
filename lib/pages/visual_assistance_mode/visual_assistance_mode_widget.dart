import 'dart:async';

import '/a11y.dart';
import '/pages/consent/consent_screen.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/mentor_log.dart';
import '/services/mentor_triggers.dart';
import '/services/platform_client.dart';
import '/student/student_profile.dart';
import '/student/student_profile_provider.dart';
import '/style/category_widgets.dart';
import '/theme.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'visual_assistance_mode_model.dart';
export 'visual_assistance_mode_model.dart';

// Visual-only constants for this screen's redesign — screen-local per the
// pattern established on the home / deaf-mode screens.
const double _kPrimaryCardRadius = 24.0;
const double _kEchoRadius = 24.0;

class VisualAssistanceModeWidget extends StatefulWidget {
  const VisualAssistanceModeWidget({super.key});

  static String routeName = 'VisualAssistanceMode';
  static String routePath = '/visualAssistanceMode';

  @override
  State<VisualAssistanceModeWidget> createState() =>
      _VisualAssistanceModeWidgetState();
}

class _VisualAssistanceModeWidgetState
    extends State<VisualAssistanceModeWidget> {
  late VisualAssistanceModeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _imagePicker = ImagePicker();

  // repeatedRequest (intensive only): counts how many times each action
  // ('describe' / 'read_text') has been used this session. The plan's
  // example is "same image re-analyzed 3 times"; the app has no "re-run last
  // analysis" affordance to compare images against, so this approximates it
  // as the same action button pressed ≥3 times in one visit to the screen —
  // flagged as a scope decision in the Phase 5 report.
  final Map<String, int> _actionCounts = {};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VisualAssistanceModeModel());
    MentorTriggers.incrementModeOpen('visual');
    PlatformClient.queueUsageEvent('mode_opened', payload: {'mode': 'visual'});
  }

  @override
  void dispose() {
    PlatformClient.flushQueuedEvents();
    // Don't let "استمع للنتيجة" keep speaking in the background after leaving.
    if (_model.isSpeaking) unawaited(actions.stopArabicSpeaking());
    _model.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze(String mode) async {
    if (!await ensureAiConsent(context)) return;
    if (!mounted) return;
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();

    safeSetState(() {
      _model.capturedImagePath = file.path;
      _model.capturedImageBytes = bytes;
      _model.isAnalyzing = true;
      _model.analysisResult = null;
      _model.isSpeaking = false;
    });

    final result = await actions.analyzeImageWithGpt4o(
      imageBytes: bytes,
      mode: mode,
    );

    safeSetState(() {
      _model.isAnalyzing = false;
      _model.analysisResult = result;
    });
    PlatformClient.queueUsageEvent('tool_used',
        payload: {'mode': 'visual', 'tool': mode});

    if (StudentProfile.current.isIntensive) {
      final count = (_actionCounts[mode] ?? 0) + 1;
      _actionCounts[mode] = count;
      if (count == 3) {
        await MentorLog.instance.log(
          mode: 'visual',
          eventType: EventType.repeatedRequest,
          severity: EventSeverity.immediate,
          details: {'action': mode, 'count': count},
        );
      }
    }
  }

  Future<void> _speakResult() async {
    if (_model.analysisResult == null) return;
    safeSetState(() => _model.isSpeaking = true);
    await actions.speakArabicText(_model.analysisResult!);
    safeSetState(() => _model.isSpeaking = false);
  }

  Future<void> _stopSpeaking() async {
    await actions.stopArabicSpeaking();
    safeSetState(() => _model.isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<StudentProfileProvider>();
    final analyzing = _model.isAnalyzing;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppColors.cream,
        // Custom header (not a real AppBar) — without SafeArea it renders
        // under the status bar, clipping the top of the page title.
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
            Container(
              color: AppColors.cream,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        18.0, AppSpacing.md, 18.0, 14.8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back button is rightmost per the Figma header
                        // (node 386:131) — first in this RTL Row renders
                        // at the row's start (right).
                        a11yButton(
                          label: 'common.back'.tr(),
                          child: Container(
                            width: 44.0,
                            height: 44.0,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(color: AppColors.border, width: 0.8),
                              boxShadow: EchoColors.shadow,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: appBackIcon(context, color: AppColors.mutedOnCream, size: 20.0),
                              onPressed: () => context.pop(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'visual.title'.tr(),
                            textAlign: TextAlign.start,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.custom(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                height: 1.45,
                                color: AppColors.onCream),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 0.8, color: AppColors.border),
                ],
              ),
            ),
              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _primaryCameraCard(analyzing),
                        const SizedBox(height: AppSpacing.lg),
                        _actionsSection(analyzing),
                        // Result
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.02),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: (_model.analysisResult != null && !analyzing)
                              ? Padding(
                                  key: const ValueKey('result'),
                                  padding: const EdgeInsets.only(
                                      top: AppSpacing.md),
                                  child: _resultCard(),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('no-result')),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      );
  }

  /// The camera/echo primary card: just the camera frame itself — a
  /// captured image when one exists, or an idle hint (generic camera
  /// glyph) otherwise — with the loading overlay preserved for the
  /// analyzing state. Figma (node 386:131) has no "جاهز"/"Ready" status
  /// chip here — the loading overlay's own "جارٍ التحليل" text already
  /// covers that state, so the chip was redundant and is dropped to match.
  Widget _primaryCameraCard(bool analyzing) {
    return Padding(
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.8),
            decoration: BoxDecoration(
              color: EchoColors.primaryBg,
              borderRadius: BorderRadius.circular(_kPrimaryCardRadius),
              border: Border.all(color: EchoColors.primaryBg),
              boxShadow: EchoColors.primaryShadow,
            ),
            child: _cameraFrame(analyzing),
          ),
        ],
      ),
    );
  }

  Widget _cameraFrame(bool analyzing) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.0),
      child: Container(
        height: 230.0,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: EchoColors.primaryWave),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: _model.capturedImagePath != null
                  ? Image.memory(
                      _model.capturedImageBytes ?? Uint8List(0),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _cameraHint(),
                    )
                  : _cameraHint(),
            ),
            // Loading overlay
            if (analyzing)
              Positioned.fill(
                child: Container(
                  color: EchoColors.primaryBg.withValues(alpha: 0.75),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.terracotta),
                      const SizedBox(height: AppSpacing.md),
                      Text('visual.analyzing'.tr(),
                          style: AppText.body(color: EchoColors.primaryText)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Idle-state hint shown before any image is captured: just a centered
  /// camera glyph — matches Figma (node 386:131) exactly, which drops the
  /// hatch background and hint caption this used to show.
  Widget _cameraHint() {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Center(
        child: Icon(Icons.photo_camera_outlined, size: 42.0, color: EchoColors.primaryWave),
      ),
    );
  }

  /// Primary CTA ("صف المحيط") in terracotta, and the secondary "اقرأ النص
  /// المطبوع" button below it. Neurodevelopmental / mild cognitive support
  /// (hidesSecondaryActions): only the primary action stays directly
  /// visible; the secondary one moves behind a quiet "خيارات" toggle.
  Widget _actionsSection(bool analyzing) {
    final describeButton = _primaryActionButton(analyzing: analyzing);
    final readTextButton = _secondaryActionButton(analyzing: analyzing);

    if (StudentProfile.current.hidesSecondaryActions) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          describeButton,
          const SizedBox(height: AppSpacing.sm),
          CollapsibleSecondaryActions(hidden: true, secondary: readTextButton),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        describeButton,
        const SizedBox(height: AppSpacing.sm),
        readTextButton,
      ],
    );
  }

  Widget _primaryActionButton({required bool analyzing}) {
    final tooltips = StudentProfile.current.showsPermanentTooltips;
    final button = a11yButton(
      enabled: !analyzing,
      label: 'visual.describeAction'.tr(),
      child: Opacity(
        opacity: analyzing ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.terracotta.withValues(alpha: 0.6),
                blurRadius: 11.0,
                offset: const Offset(0, 10.0),
              ),
            ],
          ),
          child: Material(
            color: AppColors.terracotta,
            borderRadius: BorderRadius.circular(20.0),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: analyzing ? null : () => _captureAndAnalyze('describe'),
              child: Container(
                constraints: const BoxConstraints(minHeight: 76.0),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: 18.0),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Text first (start/right), icon last (end/left) —
                    // matches Figma (node 386:131) exactly.
                    Text('visual.describeAction'.tr(),
                        textAlign: TextAlign.start,
                        style: AppText.custom(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                            color: const Color(0xFFF7F3EC))),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      width: 42.0,
                      height: 42.0,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.volume_up_rounded,
                          color: AppColors.terracotta, size: 21.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!tooltips) return button;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [button, permanentCaption('visual.describeCaption'.tr())],
    );
  }

  Widget _secondaryActionButton({required bool analyzing}) {
    final tooltips = StudentProfile.current.showsPermanentTooltips;
    final button = a11yButton(
      enabled: !analyzing,
      label: 'visual.readTextAction'.tr(),
      child: Opacity(
        opacity: analyzing ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppColors.border, width: 0.8),
            boxShadow: EchoColors.shadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(20.0),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: analyzing ? null : () => _captureAndAnalyze('read_text'),
              child: Container(
                constraints: const BoxConstraints(minHeight: 60.0),
                padding: const EdgeInsets.symmetric(horizontal: 18.8),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Text first (start/right), icon last (end/left) —
                    // matches Figma (node 386:131) exactly.
                    Text('visual.readTextAction'.tr(),
                        textAlign: TextAlign.start,
                        style: AppText.custom(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: AppColors.onCream)),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.subject_rounded, size: 22.0, color: AppColors.navy),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!tooltips) return button;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [button, permanentCaption('visual.readTextCaption'.tr())],
    );
  }

  Widget _resultCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: EchoColors.shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('visual.resultTitle'.tr(),
                style: AppText.custom(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: AppColors.mutedOnCream)),
            const SizedBox(height: AppSpacing.sm),
            a11yLive(Text(
              _model.analysisResult!,
              textAlign: TextAlign.start,
              style: AppText.custom(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.85,
                  color: AppColors.onCream),
            )),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: a11yButton(
                label: _model.isSpeaking
                    ? 'visual.stopListening'.tr()
                    : 'visual.listenToResult'.tr(),
                child: Material(
                  color: _model.isSpeaking
                      ? AppColors.terracotta
                      : AppColors.navy,
                  borderRadius: BorderRadius.circular(AppSpacing.pill),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _model.isSpeaking ? _stopSpeaking : _speakResult,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _model.isSpeaking
                                ? Icons.stop_rounded
                                : Icons.volume_up_rounded,
                            color: AppColors.onNavy,
                            size: 18.0,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                              _model.isSpeaking
                                  ? 'visual.stop'.tr()
                                  : 'visual.listenToResult'.tr(),
                              style: AppText.button(color: AppColors.onNavy)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
