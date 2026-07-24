import '/a11y.dart';
import '/components/status_badge/status_badge_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/pages/consent/consent_screen.dart';
import '/services/app_prefs.dart';
import '/services/transcript_store.dart';
import 'saved_transcripts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
            textAlign: TextAlign.end, style: GoogleFonts.cairo()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0)),
            title: Text(
              'الإعدادات',
              textAlign: TextAlign.end,
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'حجم الخط',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                Slider(
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
                Divider(),
                Text(
                  'اللغة',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('العربية', style: GoogleFonts.cairo()),
                    Radio<String>(
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
                child: Text('إغلاق', style: GoogleFonts.cairo()),
              ),
            ],
          );
        },
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
          if (i > 0) SizedBox(width: 6.0),
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
                  ? FlutterFlowTheme.of(context).error
                  : (i == 2
                      ? FlutterFlowTheme.of(context).primary
                      : i % 2 == 0
                          ? FlutterFlowTheme.of(context).primary40
                          : FlutterFlowTheme.of(context).primary60),
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
    debugPrint('🖥️ UI liveText: "${FFAppState().liveText}"');

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(shape: BoxShape.rectangle),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        32.0, 20.0, 32.0, 20.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        a11yButton(
                          label: 'رجوع',
                          child: FlutterFlowIconButton(
                          borderRadius: 8.0,
                          buttonSize: 48.0,
                          fillColor: Colors.transparent,
                          icon: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24.0,
                          ),
                          onPressed: () async {
                            context.pop();
                          },
                        ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'تحويل الكلام إلى نص',
                            textAlign: TextAlign.end,
                            style: FlutterFlowTheme.of(context)
                                .titleLarge
                                .override(
                                  font: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold),
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ),
                        a11yButton(
                          label: 'النصوص المحفوظة',
                          child: FlutterFlowIconButton(
                            borderRadius: 8.0,
                            buttonSize: 48.0,
                            fillColor: Colors.transparent,
                            icon: Icon(
                              Icons.history_rounded,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            onPressed: _openSaved,
                          ),
                        ),
                        a11yButton(
                          label: 'الإعدادات',
                          child: FlutterFlowIconButton(
                          borderRadius: 8.0,
                          buttonSize: 48.0,
                          fillColor: Colors.transparent,
                          icon: Icon(
                            Icons.settings_rounded,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 24.0,
                          ),
                          onPressed: _showSettingsDialog,
                        ),
                        ),
                      ].divide(SizedBox(width: 20.0)),
                    ),
                  ),
                  Container(
                    height: 1.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate,
                      shape: BoxShape.rectangle,
                    ),
                  ),
                ],
              ),
            ),
            // Transcription area
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        wrapWithModel(
                          model: _model.statusBadgeModel,
                          updateCallback: () => safeSetState(() {}),
                          child: StatusBadgeWidget(
                            bg: Color(0x00000000),
                            dotColor: FFAppState().isRecording
                                ? FlutterFlowTheme.of(context).error
                                : FlutterFlowTheme.of(context).success,
                            label: FFAppState().isRecording
                                ? 'جارٍ التسجيل'
                                : 'متصل',
                            textColor: Color(0x00000000),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .secondaryBackground,
                          borderRadius: BorderRadius.circular(32.0),
                          border: Border.all(
                            color: FFAppState().isRecording
                                ? FlutterFlowTheme.of(context).error
                                    .withOpacity(0.4)
                                : FlutterFlowTheme.of(context).alternate,
                            width: 2.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: SingleChildScrollView(
                            primary: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _model.sessionTitle!,
                                  style: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.cairo(),
                                        color: FlutterFlowTheme.of(context)
                                            .accent3,
                                        letterSpacing: 0.0,
                                        lineHeight: 1.4,
                                      ),
                                ),
                                Text(
                                  FFAppState().liveText.isNotEmpty
                                      ? FFAppState().liveText
                                      : (_model.liveText ?? ''),
                                  textAlign: TextAlign.end,
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        font: GoogleFonts.cairo(),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        fontSize:
                                            FFAppState().readingFontSize < 18.0
                                                ? 18.0
                                                : FFAppState().readingFontSize,
                                        letterSpacing: 0.0,
                                        lineHeight: 1.6,
                                      ),
                                ),
                                Container(
                                  width: 2.0,
                                  height: 24.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).primary,
                                    shape: BoxShape.rectangle,
                                  ),
                                ),
                              ].divide(SizedBox(height: 20.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 32.0)),
                ),
              ),
            ),
            // Controls
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 1.0,
                    color: FlutterFlowTheme.of(context).alternate,
                  ),
                  Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Animated waveform
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (context, _) {
                            return _buildWaveform(
                              FFAppState().isRecording,
                              _animController.value,
                            );
                          },
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Blinking record button
                            AnimatedBuilder(
                              animation: _animController,
                              builder: (context, child) {
                                final opacity = FFAppState().isRecording
                                    ? (0.45 +
                                        0.55 *
                                            (sin(_animController.value *
                                                        2 *
                                                        pi +
                                                    pi / 2) +
                                                1) /
                                            2)
                                    : 1.0;
                                return Opacity(opacity: opacity, child: child);
                              },
                              child: a11yButton(
                                label: FFAppState().isRecording
                                    ? 'إيقاف التسجيل'
                                    : 'بدء التسجيل',
                                child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  // Gate consent only when starting (not stopping).
                                  if (!FFAppState().isRecording) {
                                    if (!await ensureAiConsent(context)) return;
                                  }
                                  await actions.startRealtimeTranscription();
                                  safeSetState(() {});
                                },
                                child: Container(
                                  width: 88.0,
                                  height: 88.0,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(9999.0),
                                    border: Border.all(
                                      color: Color(0x33FF5252),
                                      width: 4.0,
                                    ),
                                  ),
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Container(
                                    width: 72.0,
                                    height: 72.0,
                                    decoration: BoxDecoration(
                                      color: FFAppState().isRecording
                                          ? FlutterFlowTheme.of(context).error
                                          : FlutterFlowTheme.of(context)
                                              .primary,
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 16.0,
                                          color: (FFAppState().isRecording
                                                  ? FlutterFlowTheme.of(context)
                                                      .error
                                                  : FlutterFlowTheme.of(context)
                                                      .primary)
                                              .withOpacity(0.27),
                                          offset: Offset(0.0, 8.0),
                                        )
                                      ],
                                      borderRadius:
                                          BorderRadius.circular(9999.0),
                                    ),
                                    alignment:
                                        AlignmentDirectional(0.0, 0.0),
                                    child: Icon(
                                      FFAppState().isRecording
                                          ? Icons.stop_rounded
                                          : Icons.mic_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .onPrimary,
                                      size: 36.0,
                                    ),
                                  ),
                                ),
                              ),
                              ),
                            ),
                            Text(
                              FFAppState().isRecording
                                  ? 'جاري التسجيل...'
                                  : 'اضغط للتسجيل',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold),
                                    color: FFAppState().isRecording
                                        ? FlutterFlowTheme.of(context).error
                                        : FlutterFlowTheme.of(context)
                                            .primaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    lineHeight: 1.4,
                                  ),
                            ),
                          ].divide(SizedBox(height: 20.0)),
                        ),
                        // Action buttons row
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              20.0, 0.0, 20.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _BottomButton(
                                icon: Icons.save_alt_rounded,
                                label: 'حفظ',
                                onPressed: _saveTranscript,
                              ),
                              _BottomButton(
                                icon: Icons.delete_outline_rounded,
                                label: 'مسح',
                                iconColor:
                                    FlutterFlowTheme.of(context).error,
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
                        ),
                      ].divide(SizedBox(height: 32.0)),
                    ),
                  ),
                ],
              ),
            ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FlutterFlowIconButton(
          borderRadius: 24.0,
          buttonSize: 48.0,
          fillColor: FlutterFlowTheme.of(context).surfaceVariant,
          icon: Icon(
            icon,
            color: iconColor ?? FlutterFlowTheme.of(context).primary,
            size: 24.0,
          ),
          onPressed: onPressed,
        ),
        SizedBox(height: 6.0),
        Text(
          label,
          style: FlutterFlowTheme.of(context).labelMedium.override(
                font: GoogleFonts.cairo(),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
                lineHeight: 1.4,
              ),
        ),
      ],
    ));
  }
}
