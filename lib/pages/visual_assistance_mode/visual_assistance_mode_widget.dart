import '/a11y.dart';
import '/pages/consent/consent_screen.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/mentor_log.dart';
import '/services/mentor_triggers.dart';
import '/services/platform_client.dart';
import '/student/student_profile.dart';
import '/student/student_profile_provider.dart';
import '/style/category_widgets.dart';
import '/theme.dart';
import 'dart:ui' as ui;
import '/custom_code/actions/index.dart' as actions;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'visual_assistance_mode_model.dart';
export 'visual_assistance_mode_model.dart';

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
        body: Column(
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
                        AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        a11yButton(
                          label: 'common.back'.tr(),
                          child: FlutterFlowIconButton(
                            borderRadius: 8.0,
                            buttonSize: 48.0,
                            fillColor: Colors.transparent,
                            icon: appBackIcon(context),
                            onPressed: () async {
                              context.pop();
                            },
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'visual.title'.tr(),
                            textAlign: TextAlign.start,
                            style: AppText.title(),
                          ),
                        ),
                      ].divide(const SizedBox(width: AppSpacing.sm)),
                    ),
                  ),
                  Container(height: 1.0, color: AppColors.border),
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
                        // Camera / image frame
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          child: SizedBox(
                            height: 300.0,
                            child: Stack(
                              alignment: AlignmentDirectional.center,
                              children: [
                                Positioned.fill(
                                  child: _model.capturedImagePath != null
                                      ? Image.memory(
                                          _model.capturedImageBytes ??
                                              Uint8List(0),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _cameraEmptyState(),
                                        )
                                      : _cameraEmptyState(),
                                ),
                                // Framing guide
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.cardRadius),
                                      border: Border.all(
                                        color: AppColors.onNavy
                                            .withValues(alpha: 0.3),
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                ),
                                // Scan line (accent) when idle
                                if (!analyzing)
                                  Align(
                                    alignment:
                                        const AlignmentDirectional(0.0, -0.5),
                                    child: Container(
                                      height: 2.0,
                                      color: AppColors.terracotta,
                                    ),
                                  ),
                                // Loading overlay
                                if (analyzing)
                                  Positioned.fill(
                                    child: Container(
                                      color: AppColors.navy
                                          .withValues(alpha: 0.6),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(
                                              color: AppColors.terracotta),
                                          const SizedBox(height: AppSpacing.md),
                                          Text('visual.analyzing'.tr(),
                                              style: AppText.body(
                                                  color: AppColors.onNavy)),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Status chip
                                Align(
                                  alignment:
                                      const AlignmentDirectional(0.0, -1.0),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    child: _imageStatusChip(analyzing),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Result
                        if (_model.analysisResult != null && !analyzing) ...[
                          const SizedBox(height: AppSpacing.md),
                          _resultCard(),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _actionsSection(analyzing),
                        const SizedBox(height: AppSpacing.md),
                        // Instruction
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 20.0, color: AppColors.mutedOnCream),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'visual.instruction'.tr(),
                                textAlign: TextAlign.start,
                                style: AppText.label(),
                              ),
                            ),
                          ],
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
      );
  }

  /// Both action cards side by side normally. Neurodevelopmental / mild
  /// cognitive support (hidesSecondaryActions): only "صف المحيط" (the
  /// primary action) stays visible directly; "اقرأ النص" moves behind a
  /// quiet "خيارات" toggle.
  Widget _actionsSection(bool analyzing) {
    final tooltips = StudentProfile.current.showsPermanentTooltips;
    final describeCard = _actionCard(
      icon: Icons.visibility_rounded,
      label: 'visual.describeAction'.tr(),
      enabled: !analyzing,
      onTap: () => _captureAndAnalyze('describe'),
      caption: tooltips ? 'visual.describeCaption'.tr() : null,
    );
    final readTextCard = _actionCard(
      icon: Icons.text_fields_rounded,
      label: 'visual.readTextAction'.tr(),
      enabled: !analyzing,
      onTap: () => _captureAndAnalyze('read_text'),
      caption: tooltips ? 'visual.readTextCaption'.tr() : null,
    );

    if (StudentProfile.current.hidesSecondaryActions) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          describeCard,
          const SizedBox(height: AppSpacing.md),
          CollapsibleSecondaryActions(hidden: true, secondary: readTextCard),
        ],
      );
    }

    // IntrinsicHeight gives the stretched Row a bounded height inside the
    // scroll view (equal-height cards) — plain stretch here forces infinite
    // height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: describeCard),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: readTextCard),
        ],
      ),
    );
  }

  Widget _cameraEmptyState() {
    return Container(
      color: AppColors.navy,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_rounded,
                size: 48.0, color: AppColors.onNavy.withValues(alpha: 0.7)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'visual.cameraEmptyState'.tr(),
              textAlign: TextAlign.center,
              style: AppText.label(color: AppColors.mutedOnNavy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageStatusChip(bool analyzing) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.pill),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppSpacing.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      analyzing ? AppColors.terracotta : AppColors.onNavy,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                  analyzing
                      ? 'visual.statusAnalyzing'.tr()
                      : 'visual.statusReady'.tr(),
                  style: AppText.label(color: AppColors.onNavy)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultCard() {
    return Container(
      decoration: AppDecor.creamCard(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('visual.resultTitle'.tr(), style: AppText.body(color: AppColors.onCream)),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.terracotta, size: 18.0),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            a11yLive(Text(
              _model.analysisResult!,
              textAlign: TextAlign.start,
              style: AppText.body(),
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

  /// [caption] (mild-cognitive support) renders as a permanent label under
  /// the card, outside its navy background — not a hover/long-press tooltip.
  Widget _actionCard({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    String? caption,
  }) {
    final card = a11yButton(
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Material(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg, horizontal: AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56.0,
                    height: 56.0,
                    decoration: const BoxDecoration(
                        color: AppColors.surface, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(icon, color: AppColors.navy, size: 28.0),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppText.cardTitle(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (caption == null) return card;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [card, permanentCaption(caption)],
    );
  }
}
