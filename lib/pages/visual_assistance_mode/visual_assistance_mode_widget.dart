import '/a11y.dart';
import '/pages/consent/consent_screen.dart';
import '/components/feature_button/feature_button_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VisualAssistanceModeModel());
  }

  @override
  void dispose() {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (fixed)
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.all(32.0),
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
                            Icons.arrow_back_rounded,
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
                            'التعرف البصري',
                            textAlign: TextAlign.end,
                            style: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  font: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  lineHeight: 1.4,
                                ),
                          ),
                        ),
                      ].divide(SizedBox(width: 20.0)),
                    ),
                  ),
                  Container(
                    height: 1.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Camera / Image area (fixed height)
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.0),
                        child: SizedBox(
                          height: 300.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).fullContrast,
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: Stack(
                              alignment: AlignmentDirectional(-1.0, -1.0),
                              children: [
                                // Image display
                                Positioned.fill(
                                  child: _model.capturedImagePath != null
                                      ? Image.memory(
                                          _model.capturedImageBytes ??
                                              Uint8List(0),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _placeholderImage(),
                                        )
                                      : _placeholderImage(),
                                ),
                                // Scanning border
                                Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(24.0),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .onPrimary30,
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                ),
                                // Scan line (when idle)
                                if (!_model.isAnalyzing)
                                  Align(
                                    alignment:
                                        AlignmentDirectional(0.0, -0.5),
                                    child: Container(
                                      height: 2.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 10.0,
                                            color:
                                                FlutterFlowTheme.of(context)
                                                    .primary,
                                            offset: Offset(0.0, 0.0),
                                            spreadRadius: 2.0,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                // Loading overlay
                                if (_model.isAnalyzing)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black54,
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                            ),
                                            SizedBox(height: 16.0),
                                            Text(
                                              'جارٍ التحليل...',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.cairo(),
                                                    color: Colors.white,
                                                    letterSpacing: 0.0,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                // Status badge
                                Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Align(
                                    alignment:
                                        AlignmentDirectional(0.0, -1.0),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(9999.0),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10.0,
                                          sigmaY: 10.0,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(
                                                    context)
                                                .fullContrast53,
                                            borderRadius:
                                                BorderRadius.circular(9999.0),
                                          ),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    32.0, 12.0, 32.0, 12.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 8.0,
                                                  height: 8.0,
                                                  decoration: BoxDecoration(
                                                    color: _model.isAnalyzing
                                                        ? FlutterFlowTheme.of(
                                                                context)
                                                            .primary
                                                        : FlutterFlowTheme.of(
                                                                context)
                                                            .error,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            9999.0),
                                                  ),
                                                ),
                                                Text(
                                                  _model.isAnalyzing
                                                      ? 'جارٍ التحليل'
                                                      : 'بث مباشر',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .labelMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.cairo(),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .onPrimary,
                                                        letterSpacing: 0.0,
                                                        lineHeight: 1.4,
                                                      ),
                                                ),
                                              ].divide(SizedBox(width: 12.0)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Result area
                    if (_model.analysisResult != null && !_model.isAnalyzing)
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 2.0,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'نتيجة التحليل',
                                      style: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .override(
                                            font: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    SizedBox(width: 8.0),
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      size: 18.0,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.0),
                                a11yLive(Text(
                                  _model.analysisResult!,
                                  textAlign: TextAlign.end,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.cairo(),
                                        letterSpacing: 0.0,
                                        lineHeight: 1.6,
                                      ),
                                )),
                                SizedBox(height: 12.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    a11yButton(
                                      enabled: !_model.isAnalyzing,
                                      child: GestureDetector(
                                      onTap: _model.isSpeaking
                                          ? _stopSpeaking
                                          : _speakResult,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 14.0),
                                        decoration: BoxDecoration(
                                          color: _model.isSpeaking
                                              ? FlutterFlowTheme.of(context)
                                                  .error
                                              : FlutterFlowTheme.of(context)
                                                  .primary,
                                          borderRadius:
                                              BorderRadius.circular(9999.0),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _model.isSpeaking
                                                  ? 'إيقاف'
                                                  : 'استمع للنتيجة',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .labelSmall
                                                  .override(
                                                    font: GoogleFonts.cairo(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    color:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .onPrimary,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            SizedBox(width: 6.0),
                                            Icon(
                                              _model.isSpeaking
                                                  ? Icons.stop_rounded
                                                  : Icons.volume_up_rounded,
                                              color: FlutterFlowTheme.of(
                                                      context)
                                                  .onPrimary,
                                              size: 16.0,
                                            ),
                                          ],
                                        ),
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
                    // Buttons
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 1,
                                child: a11yButton(
                                  enabled: !_model.isAnalyzing,
                                  child: GestureDetector(
                                  onTap: _model.isAnalyzing
                                      ? null
                                      : () => _captureAndAnalyze('describe'),
                                  child: Opacity(
                                    opacity:
                                        _model.isAnalyzing ? 0.5 : 1.0,
                                    child: wrapWithModel(
                                      model: _model.featureButtonModel1,
                                      updateCallback: () =>
                                          safeSetState(() {}),
                                      child: FeatureButtonWidget(
                                        icon: Icon(
                                          Icons.visibility_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .onPrimaryContainer,
                                          size: 32.0,
                                        ),
                                        label: 'صف المحيط',
                                        isComingSoon: false,
                                      ),
                                    ),
                                  ),
                                ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: a11yButton(
                                  enabled: !_model.isAnalyzing,
                                  child: GestureDetector(
                                  onTap: _model.isAnalyzing
                                      ? null
                                      : () =>
                                          _captureAndAnalyze('read_text'),
                                  child: Opacity(
                                    opacity:
                                        _model.isAnalyzing ? 0.5 : 1.0,
                                    child: wrapWithModel(
                                      model: _model.featureButtonModel2,
                                      updateCallback: () =>
                                          safeSetState(() {}),
                                      child: FeatureButtonWidget(
                                        icon: Icon(
                                          Icons.text_fields_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .onPrimaryContainer,
                                          size: 32.0,
                                        ),
                                        label: 'اقرأ النص',
                                        isComingSoon: false,
                                      ),
                                    ),
                                  ),
                                ),
                                ),
                              ),
                            ].divide(SizedBox(width: 32.0)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 20.0),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'وجه الكاميرا نحو الأشياء أو النصوص ليتم التعرف عليها تلقائياً',
                                    textAlign: TextAlign.end,
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.cairo(),
                                          letterSpacing: 0.0,
                                          lineHeight: 1.5,
                                        ),
                                  ),
                                ),
                              ].divide(SizedBox(width: 20.0)),
                            ),
                          ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                    ),
                    SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return CachedNetworkImage(
      fadeInDuration: Duration(milliseconds: 0),
      fadeOutDuration: Duration(milliseconds: 0),
      imageUrl:
          'https://dimg.dreamflow.cloud/v1/image/university%20hallway%20perspective%20view',
      fit: BoxFit.cover,
      alignment: Alignment(0.0, 0.0),
    );
  }
}
