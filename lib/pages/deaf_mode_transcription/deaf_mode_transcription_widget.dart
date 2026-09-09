import 'dart:async';
import 'dart:math';

import '/a11y.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/theme.dart';
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
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'deaf_mode_transcription_model.dart';
export 'deaf_mode_transcription_model.dart';

// Visual-only constants for this screen's redesign — screen-local per the
// pattern established on the home screen, so this pass touches only this
// file.
const double _kPrimaryCardRadius = 26.0;
const double _kEchoRadius = 26.0;

class DeafModeTranscriptionWidget extends StatefulWidget {
  const DeafModeTranscriptionWidget({super.key});

  static String routeName = 'DeafModeTranscription';
  static String routePath = '/deafModeTranscription';

  @override
  State<DeafModeTranscriptionWidget> createState() =>
      _DeafModeTranscriptionWidgetState();
}

class _DeafModeTranscriptionWidgetState
    extends State<DeafModeTranscriptionWidget> with TickerProviderStateMixin {
  late DeafModeTranscriptionModel _model;
  late AnimationController _animController;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Guards against the record toggle firing twice during a transition.
  bool _recordBusy = false;

  // Course-selection step (before recording) so this session's Deepgram
  // keyterm boost-list can include the selected course's own approved
  // lecture terms, not just the generic cross-subject dictionary — see
  // technical_terms_dictionary.dart's buildDeepgramKeytermsWithCoursePriority.
  // Auto-selected silently when the student has exactly one course; the
  // picker UI only ever appears when there's a real choice to make. Zero
  // courses degrades to no course-specific boost at all — never blocks
  // recording (task's explicit "لا تُظهر خطأ، فقط استمر" requirement).
  List<String> _courses = [];
  String? _selectedCourseCode;
  List<String> _courseKeyterms = [];
  bool _loadingCourses = true;

  // Quiet auto-summary (moderate/intensive support only) — session-only, not
  // persisted, and never touches FFAppState.liveText or the recording state.
  // No UI on this screen surfaces it (not part of the approved design); the
  // service keeps running in the background per support-level gating below.
  final _autoSummaryService = AutoSummaryService();

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
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    debugPrint('📚 _loadCourses: requesting GET /student/courses');
    final result = await PlatformClient.getStudentCourses();
    debugPrint('📚 _loadCourses: result isSuccess=${result.isSuccess} '
        '${result.isSuccess ? "count=${result.data.length} courses=${result.data}" : "error=${result.errorMessage}"}');
    if (!mounted) return;
    safeSetState(() {
      _loadingCourses = false;
      _courses = result.isSuccess ? result.data : [];
    });
    // Exactly one course: skip the picker step entirely, per the task's
    // explicit "لا تزعجه بخطوة إضافية" instruction.
    if (_courses.length == 1) {
      debugPrint('📚 _loadCourses: exactly one course — auto-selecting '
          '${_courses.first}');
      _selectCourse(_courses.first);
    } else {
      debugPrint('📚 _loadCourses: ${_courses.length} courses — '
          '${_courses.length > 1 ? "picker will show" : "no course, proceeding without course keyterms"}');
    }
  }

  Future<void> _selectCourse(String courseCode) async {
    debugPrint('📚 _selectCourse: selected=$courseCode, requesting keyterms');
    safeSetState(() => _selectedCourseCode = courseCode);
    final result = await PlatformClient.getCourseKeyterms(courseCode);
    debugPrint('📚 _selectCourse: keyterms result isSuccess=${result.isSuccess} '
        '${result.isSuccess ? "count=${result.data.length}" : "error=${result.errorMessage}"}');
    if (!mounted) return;
    // No terms yet (faculty hasn't uploaded slides) or the fetch itself
    // failed — either way this is silent, never an error shown to the
    // student: recording still works normally, just without the
    // course-specific boost (task 3's explicit requirement).
    safeSetState(() => _courseKeyterms = result.isSuccess ? result.data : []);
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

  // No UI on this screen surfaces the auto-summary result (not part of the
  // approved design) — the service still needs a callback to run, so this
  // is an intentional no-op rather than a half-wired feature.
  void _onAutoSummary(String summary) {}

  // Corrected once here so every consumer (display, save, copy, TTS,
  // auto-summary input) sees the same fixed-up text — not just the screen.
  String get _currentText =>
      correctTechnicalTerms(FFAppState().liveText.isNotEmpty
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
            textAlign: TextAlign.start,
            style: AppText.body(color: AppColors.onNavy)),
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
        style: TextStyle(
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

  /// Mic-tap handler for the new primary card's mic button — the exact
  /// original toggle logic (consent + permission gating, auto-summary
  /// start/stop, `_recordBusy` re-entrancy guard), just extracted out of the
  /// old inline `onTap` closure so `_MicButton` can call it directly.
  Future<void> _handleMicTap() async {
    debugPrint('🎙️ _handleMicTap: tapped. isRecording=${FFAppState().isRecording} '
        'recordBusy=$_recordBusy courses=${_courses.length} '
        'selectedCourse=$_selectedCourseCode courseKeyterms=${_courseKeyterms.length}');
    if (_recordBusy) return;
    _recordBusy = true;
    try {
      // Gate consent + mic permission BEFORE toggling isRecording so the OS
      // dialog can't interleave.
      if (!FFAppState().isRecording) {
        // A real choice among 2+ courses is still pending — the picker UI
        // is showing instead of the mic card's usual state; nothing to do
        // here (see _primaryMicCard's gating). Single-course/no-course
        // students never hit this (auto-selected or skipped entirely).
        if (_courses.length > 1 && _selectedCourseCode == null) {
          debugPrint('🎙️ _handleMicTap: BLOCKED — course choice pending');
          return;
        }
        if (!await ensureAiConsent(context)) {
          debugPrint('🎙️ _handleMicTap: BLOCKED — AI consent not granted');
          return;
        }
        if (!await _ensureMicPermission()) {
          debugPrint('🎙️ _handleMicTap: BLOCKED — mic permission not granted');
          return;
        }
      }
      debugPrint('🎙️ _handleMicTap: calling startRealtimeTranscription '
          'with ${_courseKeyterms.length} course keyterms');
      await actions.startRealtimeTranscription(courseKeyterms: _courseKeyterms);
      debugPrint('🎙️ _handleMicTap: startRealtimeTranscription returned, '
          'isRecording=${FFAppState().isRecording}');
      // Start/stop the quiet auto-summary alongside the recording it now
      // tracks — never touches the transcription itself either way.
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
  }

  /// True only when there's a real choice the student hasn't made yet (2+
  /// courses, none selected). Single-course and no-course students never
  /// see this — see _loadCourses' auto-select / graceful-skip logic.
  bool get _coursePickerPending =>
      !_loadingCourses && _courses.length > 1 && _selectedCourseCode == null;

  /// Course-selection step, shown above the mic card only while
  /// [_coursePickerPending] — "اختر المقرر... قبل ما يضغط زر التسجيل".
  Widget _coursePickerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_kPrimaryCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: EchoColors.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('deaf.selectCourseTitle'.tr(),
              textAlign: TextAlign.start,
              style: AppText.custom(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: AppColors.onCream)),
          const SizedBox(height: AppSpacing.sm),
          a11yButton(
            label: 'deaf.selectCourseTitle'.tr(),
            child: DropdownButtonFormField<String>(
              initialValue: null,
              hint: Text('deaf.selectCourseHint'.tr(),
                  style: AppText.body(color: AppColors.mutedOnCream)),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.navy, width: 2.0)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
              items: _courses
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) _selectCourse(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The new mic-control primary card: echo layer behind it, wave bars
  /// above the mic button, the mic button itself (with a terracotta pulse
  /// ring while recording), and the recording-state label below —
  /// replacing the old two-ring navy/terracotta record button.
  Widget _primaryMicCard(bool recording) {
    final animate = !StudentProfile.current.usesStaticAnimations;
    return Opacity(
      // Visually reflects the functional block already in _handleMicTap —
      // a pending course choice makes the mic card look inert rather than
      // just silently doing nothing on tap.
      opacity: _coursePickerPending ? 0.4 : 1.0,
      child: Padding(
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 22.0),
              decoration: BoxDecoration(
                color: EchoColors.primaryBg,
                borderRadius: BorderRadius.circular(_kPrimaryCardRadius),
                border: Border.all(color: EchoColors.primaryBg),
                boxShadow: EchoColors.primaryShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DeafWaveBars(animate: animate),
                  const SizedBox(height: AppSpacing.lg),
                  _MicButton(
                    recording: recording,
                    animate: animate,
                    label: recording
                        ? 'deaf.stopRecording'.tr()
                        : 'deaf.startRecording'.tr(),
                    onTap: _handleMicTap,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    recording
                        ? 'deaf.recordingInProgress'.tr()
                        : 'deaf.pressToRecord'.tr(),
                    textAlign: TextAlign.center,
                    style: AppText.custom(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: EchoColors.primaryText),
                  ),
                  // Mild-cognitive support: permanent caption under the
                  // primary action.
                  if (StudentProfile.current.showsPermanentTooltips)
                    permanentCaption('deaf.recordCaption'.tr()),
                ],
              ),
            ),
          ],
        ),
      ),
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
        // Custom header (not a real AppBar) — without SafeArea it renders
        // under the status bar, clipping the top of the page title.
        body: SafeArea(
          child: Column(
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
                          18.0, AppSpacing.md, 18.0, 14.8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Back button is rightmost in the Figma header
                          // (node 46:1297) — first in this RTL Row so it
                          // renders at the row's start (right), not the end.
                          a11yButton(
                            label: 'common.back'.tr(),
                            child: Container(
                              width: 44.0,
                              height: 44.0,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14.0),
                                border: Border.all(
                                    color: AppColors.border, width: 0.8),
                                boxShadow: EchoColors.shadow,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: appBackIcon(context,
                                    color: AppColors.mutedOnCream, size: 20.0),
                                onPressed: () => context.pop(),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Communication/language support only.
                          if (StudentProfile.current.showsMessageAssistant)
                            a11yButton(
                              label: 'deaf.messageAssistant'.tr(),
                              child: FlutterFlowIconButton(
                                borderRadius: 8.0,
                                buttonSize: 48.0,
                                fillColor: Colors.transparent,
                                icon: Icon(Icons.edit_note_rounded,
                                    color: AppColors.mutedOnCream, size: 24.0),
                                onPressed: _openMessageAssistant,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              'deaf.title'.tr(),
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
                            boxShadow: EchoColors.shadow,
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
                                    style: AppText.custom(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        height: 1.4,
                                        color: AppColors.mutedOnCream),
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
                    ],
                  ),
                ),
              ),
              // Controls
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.lg),
                    topRight: Radius.circular(AppSpacing.lg),
                  ),
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_coursePickerPending) ...[
                        _coursePickerCard(),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      _primaryMicCard(recording),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: _BottomButton(
                              icon: Icons.bookmark_border_rounded,
                              label: 'common.save'.tr(),
                              onPressed: _saveTranscript,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _BottomButton(
                              icon: Icons.delete_outline_rounded,
                              label: 'common.clear'.tr(),
                              onPressed: () {
                                _model.liveText = '';
                                FFAppState().update(() {
                                  FFAppState().liveText = '';
                                });
                                safeSetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _BottomButton(
                              icon: Icons.content_copy_rounded,
                              label: 'common.copy'.tr(),
                              onPressed: _copyTranscript,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(bool recording) {
    // Matches the Figma "متصل" pill exactly: soft surface capsule, border,
    // text only — no protruding status dot. While actively recording there
    // is no Figma reference for that state, so a small merged dot (soft,
    // no separate border/shadow) is kept as the minimal live-status cue.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.pill),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (recording) ...[
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.terracotta,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            recording ? 'deaf.recording'.tr() : 'common.connected'.tr(),
            style: AppText.custom(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: AppColors.mutedOnCream),
          ),
        ],
      ),
    );
  }
}

/// "shwave" — 5 looping bars (heights 40/75/100/70/35%) above the mic
/// button, purely decorative and always animating (except for
/// neurodevelopmental support, which keeps every shape static). The middle
/// bar is tinted terracotta, matching the single-accent rule used on the
/// home screen's own wave bars.
class _DeafWaveBars extends StatefulWidget {
  const _DeafWaveBars({required this.animate});

  final bool animate;

  @override
  State<_DeafWaveBars> createState() => _DeafWaveBarsState();
}

class _DeafWaveBarsState extends State<_DeafWaveBars>
    with SingleTickerProviderStateMixin {
  // Exact px heights + per-bar colors from the Figma file (node 46:1297,
  // "Container" 386:97): short soft bars, not the tall ones this used to
  // render — cream / cream / terracotta / cream / cream, fading at the
  // outer two bars.
  static const _heights = [10.449, 14.518, 14.126, 8.476, 4.429];
  static const _maxBarHeight = 14.518;
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

  Color _barColor(int i) {
    if (i == 2) return AppColors.terracotta;
    if (i == 1 || i == 3) return EchoColors.primaryText;
    return EchoColors.primaryText.withValues(alpha: 0.5);
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
              final phase = i * 0.14;
              var scale = 1.0;
              if (widget.animate) {
                final wave =
                    0.5 + 0.5 * sin(2 * pi * (_controller.value + phase));
                scale = 0.35 + 0.65 * wave;
              }
              return Padding(
                padding: EdgeInsetsDirectional.only(start: i == 0 ? 0.0 : 4.0),
                child: Container(
                  width: 4.0,
                  height: _heights[i] * scale,
                  decoration: BoxDecoration(
                    color: _barColor(i),
                    borderRadius: BorderRadius.circular(2.2),
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

/// The mic control button itself: [EchoColors.micBg]/[EchoColors.micGlyph]
/// circle with [EchoColors.micShadow], plus a terracotta "shpulse" ring
/// behind it while actively recording (suppressed for neurodevelopmental
/// support via [animate]).
class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.recording,
    required this.animate,
    required this.label,
    required this.onTap,
  });

  final bool recording;
  final bool animate;
  final String label;
  final Future<void> Function() onTap;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showPulse = widget.recording && widget.animate;
    return a11yButton(
      label: widget.label,
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: widget.onTap,
        child: SizedBox(
          width: 132.0,
          height: 132.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (showPulse)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.value;
                    return Opacity(
                      opacity: ((1.0 - t) * 0.45).clamp(0.0, 0.45),
                      child: Transform.scale(
                        scale: 1.0 + 0.35 * t,
                        child: Container(
                          width: 104.0,
                          height: 104.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              Container(
                width: 104.0,
                height: 104.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EchoColors.micBg,
                  boxShadow: EchoColors.micShadow,
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.recording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: EchoColors.micGlyph,
                  size: 38.0,
                ),
              ),
            ],
          ),
        ),
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.terracotta),
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
  State<_MessageAssistantSheet> createState() => _MessageAssistantSheetState();
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
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
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
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius)),
                ),
                onPressed: _loading ? null : _generate,
                child: _loading
                    ? SizedBox(
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
                          icon: Icon(Icons.content_copy_rounded,
                              size: 16, color: AppColors.terracotta),
                          label: Text('deaf.copyMessage'.tr(),
                              style:
                                  AppText.label(color: AppColors.terracotta)),
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

/// One of the three equal-width action cards under the mic card — matches
/// the Figma spec exactly: a soft cream card (not a bare circle+caption),
/// height 52, icon above a 13px label, both centered.
class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return a11yButton(
      child: Material(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onPressed,
          child: Container(
            height: 52.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.mutedOnCream, size: 18.0),
                const SizedBox(height: 4.0),
                Text(label, style: AppText.label(color: AppColors.mutedOnCream)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
