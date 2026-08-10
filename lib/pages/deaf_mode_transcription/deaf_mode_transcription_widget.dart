import 'dart:async';

import '/a11y.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/theme.dart';
import 'dart:math';
import '/custom_code/actions/index.dart' as actions;
import '/pages/consent/consent_screen.dart';
import '/services/ai_client.dart';
import '/services/app_prefs.dart';
import '/services/auto_summary_service.dart';
import '/services/mentor_log.dart';
import '/services/mentor_triggers.dart';
import '/services/platform_client.dart';
import '/services/technical_terms_corrector.dart';
import '/services/transcript_store.dart';
import '/student/student_profile.dart';
import '/student/student_profile_provider.dart';
import '/style/category_widgets.dart';
import 'saved_transcripts_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'deaf_mode_transcription_model.dart';
export 'deaf_mode_transcription_model.dart';

class DeafModeTranscriptionWidget extends StatefulWidget {
  const DeafModeTranscriptionWidget({super.key});

  static String routeName = 'DeafModeTranscription';
  static String routePath = '/deafModeTranscription';

  @override
  State<DeafModeTranscriptionWidget> createState() =>
      _DeafModeTranscriptionWidgetState();
}

class _DeafModeTranscriptionWidgetState
    extends State<DeafModeTranscriptionWidget>
    with TickerProviderStateMixin {
  late DeafModeTranscriptionModel _model;
  late AnimationController _animController;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Guards against the record toggle firing twice during a transition.
  bool _recordBusy = false;

  // Quiet auto-summary (moderate/intensive support only) — session-only, not
  // persisted, and never touches FFAppState.liveText or the recording state.
  final _autoSummaryService = AutoSummaryService();
  String? _autoSummary;
  bool _summaryPanelExpanded = false;
  bool _summarizingNow = false;

  // "اقرأ لي" (learning-difficulties only) — reads the live transcript aloud
  // via the existing speakArabicText/stopArabicSpeaking actions (already
  // used, unconditionally, by visual mode's "استمع للنتيجة").
  bool _isSpeakingTranscript = false;

  // midSessionAbort (intensive only) — true once the current transcript has
  // been explicitly saved via the "حفظ" button. Checked in dispose().
  bool _transcriptSaved = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DeafModeTranscriptionModel());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    MentorTriggers.incrementModeOpen('deaf');
    // Platform usage event (abstract metadata only — no transcript/PII).
    PlatformClient.queueUsageEvent('mode_opened', payload: {'mode': 'deaf'});
    // Enforce transcript retention (auto-expiry) on entry.
    AppPrefs.getRetentionDays()
        .then((days) => TranscriptStore.instance.purgeExpired(days));
  }

  @override
  void dispose() {
    // midSessionAbort (intensive only): leaving with live text that was
    // never explicitly saved. Fire-and-forget — dispose() can't be async,
    // and this is silent to the student either way.
    if (StudentProfile.current.isIntensive &&
        !_transcriptSaved &&
        _currentText.trim().isNotEmpty) {
      MentorLog.instance.log(
        mode: 'deaf',
        eventType: EventType.midSessionAbort,
        severity: EventSeverity.immediate,
        details: {'was_recording': FFAppState().isRecording},
      );
    }
    // Flush buffered platform usage events on mode close (per the buffering
    // policy: every 60s OR on mode close, whichever first). Fire-and-forget.
    PlatformClient.flushQueuedEvents();
    // Don't let "اقرأ لي" keep speaking in the background after leaving.
    if (_isSpeakingTranscript) unawaited(actions.stopArabicSpeaking());
    _animController.dispose();
    _autoSummaryService.dispose();
    _model.dispose();
    super.dispose();
  }

  void _onAutoSummary(String summary) {
    if (!mounted) return;
    safeSetState(() {
      _autoSummary = summary;
      _summarizingNow = false;
    });
  }

  /// Manual "لخّص لي الآن" (intensive support only) — a deliberate tap, so it
  /// goes through the full consent dialog (unlike the silent periodic ticks).
  Future<void> _summarizeNow() async {
    if (!await ensureAiConsent(context)) return;
    if (!mounted) return;
    safeSetState(() => _summarizingNow = true);
    await _autoSummaryService.triggerNow();
    if (mounted && _summarizingNow) {
      safeSetState(() => _summarizingNow = false);
    }
  }

  // Corrected once here so every consumer (display, save, copy, TTS,
  // auto-summary input) sees the same fixed-up text — not just the screen.
  String get _currentText => correctTechnicalTerms(
      FFAppState().liveText.isNotEmpty
          ? FFAppState().liveText
          : (_model.liveText ?? ''));

  Future<void> _toggleReadAloud() async {
    if (_isSpeakingTranscript) {
      await actions.stopArabicSpeaking();
      if (mounted) safeSetState(() => _isSpeakingTranscript = false);
      return;
    }
    final text = _currentText.trim();
    if (text.isEmpty) return;
    safeSetState(() => _isSpeakingTranscript = true);
    PlatformClient.queueUsageEvent('tool_used',
        payload: {'mode': 'deaf', 'tool': 'TEXT_TO_SPEECH'});
    await actions.speakArabicText(text);
    if (mounted) safeSetState(() => _isSpeakingTranscript = false);
  }

  /// "صياغة رسالة للأستاذ" (communication/language support only) — opens a
  /// bottom sheet asking for the message topic, then asks Gemini for a short
  /// polite phrasing. Deaf mode only, per the plan.
  Future<void> _openMessageAssistant() async {
    if (!await ensureAiConsent(context)) return;
    if (!mounted) return;
    PlatformClient.queueUsageEvent('tool_used',
        payload: {'mode': 'deaf', 'tool': 'message_assistant'});
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) => const _MessageAssistantSheet(),
    );
  }

  /// Minimum live-transcript font size for the active support level (خفيف 16
  /// / متوسط 18 / مكثف 22). The student's own settings-slider choice still
  /// wins if it's larger — this only raises the floor. Sourced from the
  /// platform's adaptation directives when a real session is loaded (see
  /// StudentProfile.deafModeFontSize), else the same local enum switch as
  /// before.
  double get _levelDefaultFontSize => StudentProfile.current.deafModeFontSize;

  Future<void> _saveTranscript() async {
    final text = _currentText.trim();
    if (text.isEmpty) {
      _snack('deaf.noTextToSave'.tr(), essential: false);
      return;
    }
    await TranscriptStore.instance.save(text);
    _transcriptSaved = true;
    _snack('deaf.textSaved'.tr(), essential: false);
  }

  void _copyTranscript() {
    final text = _currentText.trim();
    if (text.isEmpty) {
      _snack('deaf.noTextToCopy'.tr(), essential: false);
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    _snack('deaf.textCopied'.tr(), essential: false);
  }

  void _openSaved() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SavedTranscriptsPage()),
    );
  }

  /// [essential] messages (blocking errors, guidance on why something didn't
  /// happen) always show. Non-essential ones (pure success confirmations
  /// like "تم حفظ النص") are suppressed for the neurodevelopmental category
  /// (StudentProfile.minimizesNotifications) — "تقليل الإشعارات إلى الحد
  /// الأدنى" without hiding anything actionable. Behavioral/emotional
  /// support additionally softens harsh wording (AppMessages.soften).
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

  /// Requests the RECORD_AUDIO runtime permission before starting. Returns true
  /// if granted; otherwise shows an Arabic message and returns false.
  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    debugPrint('🎤 Mic permission status: $status');
    if (status.isGranted) return true;
    _snack(
        status.isPermanentlyDenied
            ? 'deaf.micBlocked'.tr()
            : 'deaf.micPermissionNeeded'.tr(),
        essential: true);
    return false;
  }

  // Font-size only. The old language radio here was dead (hardcoded to
  // 'ar', onChanged did nothing) and is now redundant with the real,
  // functional app-language choice in the global Settings screen — removed
  // rather than translated, to avoid shipping a second, misleading language
  // control.
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
            title: Text(
              'common.fontSize'.tr(),
              textAlign: TextAlign.start,
              style: AppText.title(),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  activeColor: AppColors.terracotta,
                  inactiveColor: AppColors.border,
                  value: FFAppState().readingFontSize.clamp(14.0, 32.0),
                  min: 14.0,
                  max: 32.0,
                  divisions: 9,
                  label: '${FFAppState().readingFontSize.round()}',
                  onChanged: (val) {
                    setDialogState(() {});
                    FFAppState().update(() {
                      FFAppState().readingFontSize = val;
                    });
                  },
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('common.close'.tr(),
                    style: AppText.button(color: AppColors.navy)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Live-transcript text. Intensive support additionally highlights
  /// difficult terms in AppColors.terracotta, tappable for a simplified
  /// Gemini definition in a bottom sheet.
  ///
  /// The plan mentions two kinds of difficult terms: "كلمات إنجليزية داخل
  /// النص العربي" (English words inside Arabic text) and "مصطلحات غير شائعة"
  /// (uncommon terms). Only the first is implemented — Latin-script runs are
  /// reliably detectable; "uncommon" Arabic terms would need a frequency
  /// wordlist this project doesn't have, and a naive heuristic (e.g. "long
  /// Arabic words") would misflag ordinary vocabulary. Scope decision, not
  /// an oversight.
  Widget _buildTranscriptText() {
    final style = AppText.custom(
      color: AppColors.onCream,
      fontSize: FFAppState().readingFontSize < _levelDefaultFontSize
          ? _levelDefaultFontSize
          : FFAppState().readingFontSize,
      height: 1.6,
    );

    if (!StudentProfile.current.isIntensive || _currentText.isEmpty) {
      return Text(_currentText, textAlign: TextAlign.start, style: style);
    }

    final matches = RegExp(r'[A-Za-z]{2,}').allMatches(_currentText);
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: _currentText.substring(cursor, match.start)));
      }
      final term = match.group(0)!;
      spans.add(TextSpan(
        text: term,
        style: const TextStyle(
          color: AppColors.terracotta,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w700,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _showTermDefinition(term),
      ));
      cursor = match.end;
    }
    if (cursor < _currentText.length) {
      spans.add(TextSpan(text: _currentText.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      textAlign: TextAlign.start,
    );
  }

  /// Deliberate tap (unlike the silent periodic auto-summary), so it goes
  /// through the full consent dialog.
  Future<void> _showTermDefinition(String term) async {
    if (!await ensureAiConsent(context)) return;
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (ctx) => _TermDefinitionSheet(term: term),
    );
  }

  Widget _buildWaveform(bool isRecording, double t) {
    const baseHeights = [12.0, 24.0, 40.0, 28.0, 16.0];
    const amplitudes = [8.0, 12.0, 10.0, 10.0, 6.0];
    const phases = [0.0, 0.4, 0.8, 0.2, 0.6];
    // Neurodevelopmental support: no pulsing bars — same colours convey the
    // recording state, but the shape stays still.
    final animates = isRecording && !StudentProfile.current.usesStaticAnimations;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 6.0),
          Container(
            width: 4.0,
            height: animates
                ? (baseHeights[i] +
                        sin((t + phases[i]) * 2 * pi) * amplitudes[i])
                    .abs()
                    .clamp(8.0, 52.0)
                : baseHeights[i],
            decoration: BoxDecoration(
              color: isRecording
                  ? AppColors.terracotta
                  : (i == 2
                      ? AppColors.navy
                      : AppColors.navy.withValues(alpha: i % 2 == 0 ? 0.4 : 0.6)),
              borderRadius: BorderRadius.circular(9999.0),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    // Rebuild when the debug Developer Tools screen changes the active
    // profile, so a manual level switch is reflected immediately without
    // needing to leave and re-enter this screen.
    context.watch<StudentProfileProvider>();
    final recording = FFAppState().isRecording;

    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: AppColors.cream,
          body: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                color: AppColors.cream,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                              'deaf.title'.tr(),
                              textAlign: TextAlign.start,
                              style: AppText.title(),
                            ),
                          ),
                          // Communication/language support only.
                          if (StudentProfile.current.showsMessageAssistant)
                            a11yButton(
                              label: 'deaf.messageAssistant'.tr(),
                              child: FlutterFlowIconButton(
                                borderRadius: 8.0,
                                buttonSize: 48.0,
                                fillColor: Colors.transparent,
                                icon: const Icon(Icons.edit_note_rounded,
                                    color: AppColors.mutedOnCream, size: 24.0),
                                onPressed: _openMessageAssistant,
                              ),
                            ),
                          a11yButton(
                            label: 'deaf.savedTranscripts'.tr(),
                            child: FlutterFlowIconButton(
                              borderRadius: 8.0,
                              buttonSize: 48.0,
                              fillColor: Colors.transparent,
                              icon: const Icon(Icons.history_rounded,
                                  color: AppColors.mutedOnCream, size: 24.0),
                              onPressed: _openSaved,
                            ),
                          ),
                          a11yButton(
                            label: 'common.settings'.tr(),
                            child: FlutterFlowIconButton(
                              borderRadius: 8.0,
                              buttonSize: 48.0,
                              fillColor: Colors.transparent,
                              icon: const Icon(Icons.settings_rounded,
                                  color: AppColors.mutedOnCream, size: 24.0),
                              onPressed: _showSettingsDialog,
                            ),
                          ),
                        ].divide(const SizedBox(width: AppSpacing.sm)),
                      ),
                    ),
                    Container(height: 1.0, color: AppColors.border),
                  ],
                ),
              ),
              // Transcription area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status chip
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _statusChip(recording),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                              color: recording
                                  ? AppColors.terracotta
                                  : AppColors.border,
                              width: 2.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: SingleChildScrollView(
                              primary: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'deaf.sessionTitle'.tr(),
                                    style:
                                        AppText.label(color: AppColors.mutedOnCream),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  a11yLive(_buildTranscriptText()),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // "اقرأ لي" (learning-difficulties only).
                      if (StudentProfile.current.showsReadAloudButton) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: a11yButton(
                            label: _isSpeakingTranscript
                                ? 'deaf.stopReading'.tr()
                                : 'deaf.readAloudFull'.tr(),
                            child: TextButton.icon(
                              onPressed: _currentText.trim().isEmpty
                                  ? null
                                  : _toggleReadAloud,
                              icon: Icon(
                                _isSpeakingTranscript
                                    ? Icons.stop_circle_outlined
                                    : Icons.volume_up_rounded,
                                size: 16,
                                color: AppColors.terracotta,
                              ),
                              label: Text(
                                _isSpeakingTranscript
                                    ? 'deaf.stopReading'.tr()
                                    : 'deaf.readAloud'.tr(),
                                style:
                                    AppText.label(color: AppColors.terracotta),
                              ),
                            ),
                          ),
                        ),
                      ],
                      // Quiet auto-summary (moderate/intensive only) — sits
                      // below the live transcript, never interrupts it.
                      if (StudentProfile.current
                          .isAtLeast(SupportLevel.moderate)) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (StudentProfile.current.isIntensive) ...[
                              a11yButton(
                                label: 'deaf.summarizeNow'.tr(),
                                enabled: !_summarizingNow,
                                child: TextButton.icon(
                                  onPressed:
                                      _summarizingNow ? null : _summarizeNow,
                                  icon: _summarizingNow
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.terracotta),
                                        )
                                      : const Icon(Icons.bolt_rounded,
                                          size: 16,
                                          color: AppColors.terracotta),
                                  label: Text('deaf.summarizeNow'.tr(),
                                      style: AppText.label(
                                          color: AppColors.terracotta)),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            a11yButton(
                              label: _autoSummary == null
                                  ? 'deaf.noSummaryYet'.tr()
                                  : (_summaryPanelExpanded
                                      ? 'deaf.hideSummary'.tr()
                                      : 'deaf.showSummary'.tr()),
                              enabled: _autoSummary != null,
                              child: TextButton.icon(
                                onPressed: _autoSummary == null
                                    ? null
                                    : () => safeSetState(() =>
                                        _summaryPanelExpanded =
                                            !_summaryPanelExpanded),
                                icon: Icon(
                                  _summaryPanelExpanded
                                      ? Icons.expand_less_rounded
                                      : Icons.notes_rounded,
                                  size: 16,
                                  color: AppColors.mutedOnCream,
                                ),
                                label: Text(
                                  _autoSummary == null
                                      ? 'deaf.noSummaryYet'.tr()
                                      : (_summaryPanelExpanded
                                          ? 'deaf.hideSummary'.tr()
                                          : 'deaf.showSummary'.tr()),
                                  style: AppText.label(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_summaryPanelExpanded && _autoSummary != null)
                          Container(
                            margin: const EdgeInsets.only(top: AppSpacing.xs),
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: AppDecor.creamCard(),
                            child: a11yLive(Text(_autoSummary!,
                                textAlign: TextAlign.start,
                                style: AppText.body())),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              // Controls
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.lg),
                    topRight: Radius.circular(AppSpacing.lg),
                  ),
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) => _buildWaveform(
                            FFAppState().isRecording, _animController.value),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Blinking record button — static (no pulse) for
                      // neurodevelopmental support.
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final opacity = (FFAppState().isRecording &&
                                  !StudentProfile.current.usesStaticAnimations)
                              ? (0.5 +
                                  0.5 *
                                      (sin(_animController.value * 2 * pi +
                                                  pi / 2) +
                                              1) /
                                          2)
                              : 1.0;
                          return Opacity(opacity: opacity, child: child);
                        },
                        child: a11yButton(
                          label: recording
                              ? 'deaf.stopRecording'.tr()
                              : 'deaf.startRecording'.tr(),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              // Re-entrancy guard: ignore taps while a start/stop
                              // transition is in flight, so the toggle can't fire
                              // twice (which showed as an immediate stop).
                              if (_recordBusy) return;
                              _recordBusy = true;
                              try {
                                // Gate consent + mic permission BEFORE toggling
                                // isRecording so the OS dialog can't interleave.
                                if (!FFAppState().isRecording) {
                                  if (!await ensureAiConsent(context)) return;
                                  if (!await _ensureMicPermission()) return;
                                }
                                await actions.startRealtimeTranscription();
                                // Start/stop the quiet auto-summary alongside
                                // the recording it now tracks — never touches
                                // the transcription itself either way.
                                if (FFAppState().isRecording) {
                                  _autoSummaryService.start(
                                    latestText: () => _currentText,
                                    onSummary: _onAutoSummary,
                                  );
                                } else {
                                  _autoSummaryService.stop();
                                }
                                if (mounted) safeSetState(() {});
                              } finally {
                                _recordBusy = false;
                              }
                            },
                            child: Container(
                              width: 88.0,
                              height: 88.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (recording
                                          ? AppColors.terracotta
                                          : AppColors.navy)
                                      .withValues(alpha: 0.2),
                                  width: 4.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 72.0,
                                height: 72.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: recording
                                      ? AppColors.terracotta
                                      : AppColors.navy,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 16.0,
                                      color: (recording
                                              ? AppColors.terracotta
                                              : AppColors.navy)
                                          .withValues(alpha: 0.27),
                                      offset: const Offset(0.0, 8.0),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  recording
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  color: AppColors.onNavy,
                                  size: 36.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        recording
                            ? 'deaf.recordingInProgress'.tr()
                            : 'deaf.pressToRecord'.tr(),
                        style: AppText.title(
                            color: recording
                                ? AppColors.terracotta
                                : AppColors.onCream),
                      ),
                      // Mild-cognitive support: permanent caption under the
                      // primary action.
                      if (StudentProfile.current.showsPermanentTooltips)
                        permanentCaption('deaf.recordCaption'.tr()),
                      const SizedBox(height: AppSpacing.lg),
                      // Secondary actions — hidden behind "خيارات" for
                      // neurodevelopmental / mild-cognitive support.
                      CollapsibleSecondaryActions(
                        hidden: StudentProfile.current.hidesSecondaryActions,
                        secondary: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _BottomButton(
                              icon: Icons.save_alt_rounded,
                              label: 'common.save'.tr(),
                              onPressed: _saveTranscript,
                            ),
                            _BottomButton(
                              icon: Icons.delete_outline_rounded,
                              label: 'common.clear'.tr(),
                              iconColor: AppColors.error,
                              onPressed: () {
                                _model.liveText = '';
                                FFAppState().update(() {
                                  FFAppState().liveText = '';
                                });
                                safeSetState(() {});
                              },
                            ),
                            _BottomButton(
                              icon: Icons.content_copy_rounded,
                              label: 'common.copy'.tr(),
                              onPressed: _copyTranscript,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _statusChip(bool recording) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: recording ? AppColors.terracotta : AppColors.navy,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            recording ? 'deaf.recording'.tr() : 'common.connected'.tr(),
            style: AppText.label(color: AppColors.mutedOnCream),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for the intensive-support difficult-term tap: fetches a
/// short, simple definition from Gemini (a separate "simple prompt" call,
/// not the vision/learning adaptive_prompts.dart machinery — matching how
/// the plan describes these auxiliary calls).
class _TermDefinitionSheet extends StatefulWidget {
  const _TermDefinitionSheet({required this.term});

  final String term;

  @override
  State<_TermDefinitionSheet> createState() => _TermDefinitionSheetState();
}

class _TermDefinitionSheetState extends State<_TermDefinitionSheet> {
  String? _definition;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await aiChatCompletion(
      maxTokens: 150,
      messages: [
        {
          'role': 'user',
          'content': AppPrefs.currentAppLanguage == 'en'
              ? 'Explain the meaning of the term "${widget.term}" in one '
                  'very short, very simple English sentence, suitable for '
                  'a student who needs intensive support.'
              : 'اشرح معنى المصطلح "${widget.term}" بجملة واحدة قصيرة جداً وبسيطة جداً بالعربية، مناسبة لطالب يحتاج دعماً مكثفاً.',
        },
      ],
    );
    if (!mounted) return;
    setState(() {
      if (result.ok) {
        _definition = result.content;
      } else {
        _error = result.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.pill),
              ),
            ),
            Text(widget.term,
                textAlign: TextAlign.start,
                style: AppText.title(color: AppColors.terracotta)),
            const SizedBox(height: AppSpacing.md),
            if (_definition == null && _error == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.terracotta),
                ),
              )
            else
              a11yLive(Text(_definition ?? _error!,
                  textAlign: TextAlign.start, style: AppText.body())),
          ],
        ),
      ),
    );
  }
}

/// "صياغة رسالة للأستاذ" bottom sheet (communication/language support,
/// deaf mode only): student states a topic, Gemini drafts a short polite
/// message, shown with a copy button. Separate simple prompt call — not the
/// adaptive_prompts.dart machinery, matching how the plan frames these
/// small auxiliary Gemini calls.
class _MessageAssistantSheet extends StatefulWidget {
  const _MessageAssistantSheet();

  @override
  State<_MessageAssistantSheet> createState() =>
      _MessageAssistantSheetState();
}

class _MessageAssistantSheetState extends State<_MessageAssistantSheet> {
  final _topicController = TextEditingController();
  bool _loading = false;
  String? _draft;
  String? _error;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _draft = null;
      _error = null;
    });
    final result = await aiChatCompletion(
      maxTokens: 200,
      messages: [
        {
          'role': 'user',
          'content': AppPrefs.currentAppLanguage == 'en'
              ? 'Write a short, polite, formal English message from a '
                  'university student to their instructor, about: $topic. '
                  'Keep it brief and direct, no long preamble.'
              : 'اكتب رسالة قصيرة ومهذبة بصيغة رسمية باللغة العربية، موجّهة من طالب جامعي لأستاذه، بخصوص: $topic. اجعلها مختصرة ومباشرة، بلا مقدمات طويلة.',
        },
      ],
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _draft = result.content;
      } else {
        _error = result.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSpacing.pill),
              ),
            ),
            Text('deaf.messageAssistantTitle'.tr(),
                textAlign: TextAlign.start, style: AppText.title()),
            const SizedBox(height: AppSpacing.sm),
            Text('deaf.messageAssistantSubtitle'.tr(),
                textAlign: TextAlign.start,
                style: AppText.label(color: AppColors.mutedOnCream)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _topicController,
              textAlign: TextAlign.start,
              maxLines: 3,
              style: AppText.body(color: AppColors.onCream),
              cursorColor: AppColors.terracotta,
              decoration: InputDecoration(
                hintText: 'deaf.messageAssistantHint'.tr(),
                hintStyle: AppText.body(color: AppColors.mutedOnCream),
                enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.navy, width: 2.0)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            a11yButton(
              label: 'deaf.generateMessage'.tr(),
              enabled: !_loading,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.onNavy,
                  minimumSize: const Size.fromHeight(AppSpacing.minTap),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
                ),
                onPressed: _loading ? null : _generate,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.onNavy),
                      )
                    : Text('deaf.generateMessage'.tr(),
                        style: AppText.button(color: AppColors.onNavy)),
              ),
            ),
            if (_draft != null || _error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: AppDecor.creamCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    a11yLive(Text(_draft ?? _error!,
                        textAlign: TextAlign.start, style: AppText.body())),
                    if (_draft != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      a11yButton(
                        label: 'deaf.copyMessage'.tr(),
                        child: TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _draft!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('deaf.messageCopied'.tr(),
                                    textAlign: TextAlign.start,
                                    style:
                                        AppText.body(color: AppColors.onNavy)),
                                backgroundColor: AppColors.navy,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.content_copy_rounded,
                              size: 16, color: AppColors.terracotta),
                          label: Text('deaf.copyMessage'.tr(),
                              style: AppText.label(color: AppColors.terracotta)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return a11yButton(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlutterFlowIconButton(
            borderRadius: 24.0,
            buttonSize: 48.0,
            fillColor: AppColors.cream,
            borderColor: AppColors.border,
            borderWidth: 1.0,
            icon: Icon(icon, color: iconColor ?? AppColors.navy, size: 24.0),
            onPressed: onPressed,
          ),
          const SizedBox(height: 6.0),
          Text(label, style: AppText.label(color: AppColors.mutedOnCream)),
        ],
      ),
    );
  }
}
