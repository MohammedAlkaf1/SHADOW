import 'dart:async';

import '/a11y.dart';
import '/pages/consent/consent_screen.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/mentor_log.dart';
import '/services/mentor_triggers.dart';
import '/services/platform_client.dart';
import '/services/technical_terms_corrector.dart';
import '/student/student_profile.dart';
import '/student/student_profile_provider.dart';
import '/style/category_widgets.dart';
import '/theme.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'learning_support_mode_model.dart';
export 'learning_support_mode_model.dart';

// Visual-only constants for this screen's redesign — screen-local per the
// pattern established on the home / deaf-mode screens.
const double _kPrimaryCardRadius = 24.0;
const double _kEchoRadius = 24.0;

class LearningSupportModeWidget extends StatefulWidget {
  const LearningSupportModeWidget({super.key});

  static String routeName = 'LearningSupportMode';
  static String routePath = '/learningSupportMode';

  @override
  State<LearningSupportModeWidget> createState() =>
      _LearningSupportModeWidgetState();
}

class _LearningSupportModeWidgetState extends State<LearningSupportModeWidget> {
  late LearningSupportModeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // "اقرأ لي" (learning-difficulties only) on the AI result.
  bool _isSpeakingResult = false;

  // sameFileMultipleTimes (intensive only): counts "تبسيط" presses on the
  // currently loaded file; reset whenever a new file is picked.
  int _simplifyCountForCurrentFile = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LearningSupportModeModel());
    MentorTriggers.incrementModeOpen('learning');
    PlatformClient.queueUsageEvent('mode_opened',
        payload: {'mode': 'learning'});
  }

  @override
  void dispose() {
    PlatformClient.flushQueuedEvents();
    // Don't let "اقرأ لي" keep speaking in the background after leaving.
    if (_isSpeakingResult) unawaited(actions.stopArabicSpeaking());
    _model.dispose();
    super.dispose();
  }

  /// [essential] messages (blocking errors, guidance on why something didn't
  /// happen) always show. Non-essential ones are suppressed for the
  /// neurodevelopmental category (StudentProfile.minimizesNotifications).
  /// Behavioral/emotional support additionally softens harsh wording.
  void _snack(String message, {required bool essential}) {
    if (!mounted) return;
    final profile = StudentProfile.current;
    if (!essential && profile.minimizesNotifications) return;
    final text =
        AppMessages.soften(message, enabled: profile.softensErrorMessages);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text,
            textAlign: TextAlign.start, style: AppText.body(color: AppColors.onNavy)),
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickPdfFile() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // load bytes so cloud files (no local path) still work
      );
    } catch (e) {
      // Cloud-backed files (e.g. OneDrive) can throw PlatformException.
      debugPrint('file_picker failed: $e');
      _snack('learning.filePickFailed'.tr(), essential: true);
      return;
    }
    if (result == null) return; // user cancelled

    final file = result.files.single;
    if (file.bytes == null) {
      _snack('learning.filePickFailed'.tr(), essential: true);
      return;
    }
    safeSetState(() {
      _model.pdfFilePath = null;
      _model.pdfFileBytes = file.bytes;
      _model.currentDocName = '"${file.name}"';
      _model.aiResult = null;
      _model.extractedText = null;
    });
    _simplifyCountForCurrentFile = 0;

    // Learning-difficulties: summarize automatically, no button press needed.
    if (StudentProfile.current.autoSummarizesByDefault) {
      await _processDocument('summarize');
    }
  }

  Future<void> _processDocument(String mode) async {
    if (!await ensureAiConsent(context)) return;
    if (!mounted) return;
    if (_model.pdfFileBytes == null) {
      _snack('learning.chooseFileFirst'.tr(), essential: true);
      return;
    }

    safeSetState(() {
      _model.isProcessing = true;
      _model.aiResult = null;
      _isSpeakingResult = false;
    });

    final result = await actions.processDocumentWithGpt4o(
      fileBytes: _model.pdfFileBytes,
      mode: mode,
    );

    safeSetState(() {
      _model.isProcessing = false;
      // Simplified/summarized academic text can still contain technical
      // terms Gemini kept in Arabic phonetic form; correct once here so
      // both the on-screen result and "اقرأ لي" TTS see the fixed text.
      _model.aiResult = correctTechnicalTerms(result);
    });

    // sameFileMultipleTimes (intensive only): "تبسيط" ≥5 times on this file.
    if (mode == 'simplify' && StudentProfile.current.isIntensive) {
      _simplifyCountForCurrentFile++;
      if (_simplifyCountForCurrentFile == 5) {
        await MentorLog.instance.log(
          mode: 'learning',
          eventType: EventType.sameFileMultipleTimes,
          severity: EventSeverity.immediate,
          details: {
            'action': 'simplify',
            'count': _simplifyCountForCurrentFile,
          },
        );
      }
    }
  }

  Future<void> _toggleReadAloud() async {
    if (_isSpeakingResult) {
      await actions.stopArabicSpeaking();
      if (mounted) safeSetState(() => _isSpeakingResult = false);
      return;
    }
    final text = _model.aiResult;
    if (text == null || text.trim().isEmpty) return;
    safeSetState(() => _isSpeakingResult = true);
    await actions.speakArabicText(text);
    if (mounted) safeSetState(() => _isSpeakingResult = false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    context.watch<StudentProfileProvider>();
    final hasDoc = (_model.pdfFileBytes != null);

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
              _header('learning.title'.tr()),
              Expanded(
                child: SingleChildScrollView(
                  primary: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _uploadCard(hasDoc),
                        const SizedBox(height: AppSpacing.lg),
                        // Assistant section title
                        Text('learning.assistant'.tr(),
                            style: AppText.custom(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                                color: AppColors.mutedOnCream)),
                        const SizedBox(height: AppSpacing.sm),
                        _assistantButtons(),
                        // Loading / result
                        if (_model.isProcessing) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            decoration: AppDecor.creamCard(),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20.0,
                                    height: 20.0,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        color: AppColors.terracotta),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text('learning.processing'.tr(),
                                      style: AppText.body()),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                          child: (_model.aiResult != null &&
                                  !_model.isProcessing)
                              ? Padding(
                                  key: const ValueKey('result'),
                                  padding: const EdgeInsets.only(
                                      top: AppSpacing.md),
                                  child: _resultCard(),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('no-result')),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _fontSizeCard(),
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

  /// Primary upload echo card: file glyph, title/subtitle, terracotta pill
  /// CTA, and — once a file is picked — a fading-in row showing the
  /// filename with a terracotta square bullet.
  Widget _uploadCard(bool hasDoc) {
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
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: EchoColors.primaryBg,
              borderRadius: BorderRadius.circular(_kPrimaryCardRadius),
              border: Border.all(color: EchoColors.primaryBg),
              boxShadow: EchoColors.primaryShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _fileGlyph(),
                const SizedBox(height: AppSpacing.md),
                Text('learning.uploadTitle'.tr(),
                    textAlign: TextAlign.center,
                    style: AppText.custom(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                        color: EchoColors.primaryText)),
                const SizedBox(height: AppSpacing.xs),
                Text('learning.uploadSub'.tr(),
                    textAlign: TextAlign.center,
                    style: AppText.custom(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: EchoColors.primarySub)),
                const SizedBox(height: AppSpacing.lg),
                a11yButton(
                  label: 'learning.chooseFile'.tr(),
                  child: Material(
                    color: AppColors.terracotta,
                    borderRadius: BorderRadius.circular(AppSpacing.pill),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _pickPdfFile,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.pill),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.terracotta
                                  .withValues(alpha: 0.35),
                              blurRadius: 16.0,
                              offset: const Offset(0, 6.0),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl, vertical: 14.0),
                        child: Text('learning.chooseFile'.tr(),
                            style: AppText.button(color: AppColors.cream)),
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: hasDoc
                      ? Padding(
                          key: const ValueKey('doc-name'),
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.0,
                                height: 8.0,
                                color: AppColors.terracotta,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  _model.currentDocName ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.custom(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                      color: EchoColors.primarySub),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-doc-name')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Circular file glyph — matches Figma (node 386:554) exactly: a soft
  /// translucent-cream circle with a generic document icon.
  Widget _fileGlyph() {
    return Container(
      width: 54.0,
      height: 54.0,
      decoration: BoxDecoration(
        color: EchoColors.primaryText.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(17.0),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.description_rounded, size: 26.0, color: EchoColors.primaryBg),
    );
  }

  /// All three buttons normally. Neurodevelopmental / mild cognitive support
  /// (hidesSecondaryActions): only "تلخيص" (the primary action — also the
  /// one auto-run for learning difficulties) stays directly visible;
  /// "تبسيط" and "أسئلة مراجعة" move behind a quiet "خيارات" toggle.
  Widget _assistantButtons() {
    final tooltips = StudentProfile.current.showsPermanentTooltips;
    final summarize = _summarizeButton(tooltips: tooltips);
    final secondaryRow = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
              child: _secondaryToolButton(
            label: 'learning.quiz'.tr(),
            icon: Icons.help_outline_rounded,
            onTap: () => _processDocument('quiz'),
            caption: tooltips ? 'learning.quizCaption'.tr() : null,
          )),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _secondaryToolButton(
            label: 'learning.simplify'.tr(),
            icon: Icons.layers_outlined,
            onTap: () => _processDocument('simplify'),
            caption: tooltips ? 'learning.simplifyCaption'.tr() : null,
          )),
        ],
      ),
    );

    if (StudentProfile.current.hidesSecondaryActions) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          summarize,
          const SizedBox(height: AppSpacing.sm),
          CollapsibleSecondaryActions(hidden: true, secondary: secondaryRow),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        summarize,
        const SizedBox(height: AppSpacing.sm),
        secondaryRow,
      ],
    );
  }

  /// The primary tool — "تلخيص" — visually distinct from the two secondary
  /// tools: a terracotta-bordered surface card with a terracotta icon tile.
  Widget _summarizeButton({required bool tooltips}) {
    final button = a11yButton(
      enabled: !_model.isProcessing,
      label: 'learning.summarize'.tr(),
      child: Opacity(
        opacity: _model.isProcessing ? 0.5 : 1.0,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _model.isProcessing
                ? null
                : () => _processDocument('summarize'),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: EchoColors.shadow,
              ),
              constraints: const BoxConstraints(minHeight: 76.0),
              padding: const EdgeInsets.symmetric(horizontal: 18.8, vertical: 16.8),
              child: Row(
                children: [
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: AppColors.terracotta,
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.auto_awesome_rounded,
                        color: AppColors.cream, size: 22.0),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('learning.summarize'.tr(),
                        textAlign: TextAlign.start,
                        style: AppText.custom(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                            color: AppColors.onCream)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!tooltips) return button;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [button, permanentCaption('learning.summarizeCaption'.tr())],
    );
  }

  Widget _secondaryToolButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    String? caption,
  }) {
    final button = a11yButton(
      enabled: !_model.isProcessing,
      label: label,
      child: Opacity(
        opacity: _model.isProcessing ? 0.5 : 1.0,
        child: Material(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(16.0),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _model.isProcessing ? null : onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md, horizontal: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.navy, size: 22.0),
                  const SizedBox(height: 6.0),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppText.custom(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AppColors.onCream),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (caption == null) return button;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [button, permanentCaption(caption)],
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
            Text('learning.result'.tr(),
                style: AppText.custom(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: AppColors.mutedOnCream)),
            const SizedBox(height: AppSpacing.sm),
            // Adaptive font size: comes from the real slider/FFAppState
            // value below — never hardcoded.
            a11yLive(Text(
              _model.aiResult!,
              textAlign: TextAlign.start,
              style: AppText.custom(
                color: AppColors.onCream,
                fontSize: FFAppState().readingFontSize < 18.0
                    ? 18.0
                    : FFAppState().readingFontSize,
                height: 1.6,
              ),
            )),
            // "اقرأ لي" (learning-difficulties only).
            if (StudentProfile.current.showsReadAloudButton) ...[
              const SizedBox(height: AppSpacing.sm),
              a11yButton(
                label: _isSpeakingResult
                    ? 'learning.stopReading'.tr()
                    : 'learning.readResultAloud'.tr(),
                child: TextButton.icon(
                  onPressed: _toggleReadAloud,
                  icon: Icon(
                    _isSpeakingResult
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_rounded,
                    size: 16,
                    color: AppColors.terracotta,
                  ),
                  label: Text(
                    _isSpeakingResult
                        ? 'learning.stopReading'.tr()
                        : 'learning.readAloud'.tr(),
                    style: AppText.label(color: AppColors.terracotta),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(String title) {
    return Container(
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
                // Back button is rightmost per the Figma header (node
                // 386:554) — first in this RTL Row renders at the row's
                // start (right).
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
                  child: Text(title,
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.custom(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.45,
                          color: AppColors.onCream)),
                ),
              ],
            ),
          ),
          Container(height: 0.8, color: AppColors.border),
        ],
      ),
    );
  }

  /// Font-size control card — wraps the EXISTING adaptive font-size slider
  /// (FFAppState.readingFontSize, unmodified interaction/behavior) in the
  /// new card visual style, per the design brief.
  Widget _fontSizeCard() {
    final size = FFAppState().readingFontSize.clamp(14.0, 32.0);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('common.fontSize'.tr(),
                    style: AppText.custom(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: AppColors.onCream)),
                Text('${size.round()}',
                    style: AppText.custom(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: AppColors.terracotta)),
              ],
            ),
            Slider(
              activeColor: AppColors.terracotta,
              inactiveColor: AppColors.border,
              value: size,
              min: 14.0,
              max: 32.0,
              divisions: 9,
              label: '${size.round()}',
              onChanged: (val) {
                FFAppState().update(() {
                  FFAppState().readingFontSize = val;
                });
                safeSetState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
