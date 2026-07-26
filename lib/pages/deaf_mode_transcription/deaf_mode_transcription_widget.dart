import '/a11y.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/theme.dart';
import 'dart:math';
import 'dart:ui' as ui;
import '/custom_code/actions/index.dart' as actions;
import '/pages/consent/consent_screen.dart';
import '/services/app_prefs.dart';
import '/services/transcript_store.dart';
import 'saved_transcripts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DeafModeTranscriptionModel());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    // Enforce transcript retention (auto-expiry) on entry.
    AppPrefs.getRetentionDays()
        .then((days) => TranscriptStore.instance.purgeExpired(days));
  }

  @override
  void dispose() {
    _animController.dispose();
    _model.dispose();
    super.dispose();
  }

  String get _currentText => FFAppState().liveText.isNotEmpty
      ? FFAppState().liveText
      : (_model.liveText ?? '');

  Future<void> _saveTranscript() async {
    final text = _currentText.trim();
    if (text.isEmpty) {
      _snack('لا يوجد نص لحفظه');
      return;
    }
    await TranscriptStore.instance.save(text);
    _snack('تم حفظ النص');
  }

  void _copyTranscript() {
    final text = _currentText.trim();
    if (text.isEmpty) {
      _snack('لا يوجد نص لنسخه');
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    _snack('تم نسخ النص');
  }

  void _openSaved() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SavedTranscriptsPage()),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            textAlign: TextAlign.end, style: AppText.body(color: AppColors.onNavy)),
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
    _snack(status.isPermanentlyDenied
        ? 'الميكروفون محظور. فعّله من إعدادات التطبيق للسماح بالتسجيل.'
        : 'يرجى السماح باستخدام الميكروفون لتشغيل التسجيل.');
    return false;
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0)),
              title: Text(
                'الإعدادات',
                textAlign: TextAlign.end,
                style: AppText.title(),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('حجم الخط', textAlign: TextAlign.end, style: AppText.body()),
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
                  const Divider(color: AppColors.border),
                  Text('اللغة', textAlign: TextAlign.end, style: AppText.body()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('العربية', style: AppText.label(color: AppColors.onCream)),
                      Radio<String>(
                        activeColor: AppColors.navy,
                        value: 'ar',
                        groupValue: 'ar',
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.start,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('إغلاق',
                      style: AppText.button(color: AppColors.navy)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaveform(bool isRecording, double t) {
    const baseHeights = [12.0, 24.0, 40.0, 28.0, 16.0];
    const amplitudes = [8.0, 12.0, 10.0, 10.0, 6.0];
    const phases = [0.0, 0.4, 0.8, 0.2, 0.6];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 6.0),
          Container(
            width: 4.0,
            height: isRecording
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
    final recording = FFAppState().isRecording;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: GestureDetector(
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
                            label: 'رجوع',
                            child: FlutterFlowIconButton(
                              borderRadius: 8.0,
                              buttonSize: 48.0,
                              fillColor: Colors.transparent,
                              icon: const Icon(Icons.arrow_back_ios_rounded,
                                  color: AppColors.onCream, size: 22.0),
                              onPressed: () async {
                                context.pop();
                              },
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'تحويل الكلام إلى نص',
                              textAlign: TextAlign.end,
                              style: AppText.title(),
                            ),
                          ),
                          a11yButton(
                            label: 'النصوص المحفوظة',
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
                            label: 'الإعدادات',
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
                        alignment: AlignmentDirectional.centerEnd,
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
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _model.sessionTitle!,
                                    style:
                                        AppText.label(color: AppColors.mutedOnCream),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  a11yLive(Text(
                                    _currentText,
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.tajawal(
                                      color: AppColors.onCream,
                                      fontSize: FFAppState().readingFontSize < 18.0
                                          ? 18.0
                                          : FFAppState().readingFontSize,
                                      height: 1.6,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
                      // Blinking record button
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final opacity = FFAppState().isRecording
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
                          label: recording ? 'إيقاف التسجيل' : 'بدء التسجيل',
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
                        recording ? 'جاري التسجيل...' : 'اضغط للتسجيل',
                        style: AppText.title(
                            color: recording
                                ? AppColors.terracotta
                                : AppColors.onCream),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Action buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _BottomButton(
                            icon: Icons.save_alt_rounded,
                            label: 'حفظ',
                            onPressed: _saveTranscript,
                          ),
                          _BottomButton(
                            icon: Icons.delete_outline_rounded,
                            label: 'مسح',
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
                            label: 'نسخ',
                            onPressed: _copyTranscript,
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
            recording ? 'جارٍ التسجيل' : 'متصل',
            style: AppText.label(color: AppColors.mutedOnCream),
          ),
        ],
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
