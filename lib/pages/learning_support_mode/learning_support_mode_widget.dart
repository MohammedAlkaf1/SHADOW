import '/a11y.dart';
import '/components/button/button_widget.dart';
import '/components/mode_header/mode_header_widget.dart';
import '/components/slider/slider_widget.dart';
import '/components/text_block/text_block_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'learning_support_mode_model.dart';
export 'learning_support_mode_model.dart';

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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LearningSupportModeModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return;

    final file = result.files.single;
    safeSetState(() {
      _model.pdfFilePath = null;
      _model.pdfFileBytes = file.bytes;
      _model.currentDocName = '"${file.name}"';
      _model.aiResult = null;
      _model.extractedText = null;
    });
  }

  Future<void> _processDocument(String mode) async {
    if (_model.pdfFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى اختيار ملف PDF أولاً',
            textAlign: TextAlign.end,
            style: GoogleFonts.cairo(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    safeSetState(() {
      _model.isProcessing = true;
      _model.aiResult = null;
    });

    final result = await actions.processDocumentWithGpt4o(
      fileBytes: _model.pdfFileBytes,
      mode: mode,
    );

    safeSetState(() {
      _model.isProcessing = false;
      _model.aiResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

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
            a11yButton(
              label: 'رجوع',
              child: InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                context.pop();
              },
              child: wrapWithModel(
                model: _model.modeHeaderModel,
                updateCallback: () => safeSetState(() {}),
                child: ModeHeaderWidget(
                  icon: Icon(
                    Icons.psychology_rounded,
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                  title: 'دعم التعلم',
                ),
              ),
            ),
            ),
            // Scrollable content
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                primary: false,
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Upload area
                      Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          borderRadius: BorderRadius.circular(32.0),
                          shape: BoxShape.rectangle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_rounded,
                                color:
                                    FlutterFlowTheme.of(context).onPrimary,
                                size: 48.0,
                              ),
                              Text(
                                'رفع ملف PDF للمحاضرة',
                                style: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .override(
                                      font: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold),
                                      color: FlutterFlowTheme.of(context)
                                          .onPrimary,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      lineHeight: 1.4,
                                    ),
                              ),
                              a11yButton(
                                child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: _pickPdfFile,
                                child: wrapWithModel(
                                  model: _model.buttonModel,
                                  updateCallback: () => safeSetState(() {}),
                                  child: ButtonWidget(
                                    content: 'اختر ملفاً',
                                    iconPresent: false,
                                    iconEndPresent: false,
                                    variant: 'primary',
                                    size: 'medium',
                                    fullWidth: false,
                                    loading: false,
                                    disabled: false,
                                  ),
                                ),
                              ),
                              ),
                            ].divide(SizedBox(height: 20.0)),
                          ),
                        ),
                      ),
                      // File name + text block
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 34.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context)
                                        .alternate,
                                    width: 1.0,
                                  ),
                                ),
                                alignment: AlignmentDirectional(0.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      12.0, 0.0, 12.0, 0.0),
                                  child: Text(
                                    'قيد القراءة',
                                    style: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.cairo(),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                ),
                              ),
                              Text(
                                _model.currentDocName!,
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.cairo(),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      lineHeight: 1.4,
                                    ),
                              ),
                            ],
                          ),
                          wrapWithModel(
                            model: _model.textBlockModel,
                            updateCallback: () => safeSetState(() {}),
                            child: TextBlockWidget(
                              size: FFAppState().readingFontSize,
                              content: _model.extractedText,
                            ),
                          ),
                        ].divide(SizedBox(height: 20.0)),
                      ),
                      // AI action buttons
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: FlutterFlowTheme.of(context).primary,
                                size: 18.0,
                              ),
                              SizedBox(width: 8.0),
                              Text(
                                'المساعد الذكي',
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold),
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              _AiActionButton(
                                label: 'تلخيص',
                                icon: Icons.summarize_rounded,
                                isLoading: _model.isProcessing,
                                onTap: () => _processDocument('summarize'),
                              ),
                              _AiActionButton(
                                label: 'تبسيط',
                                icon: Icons.lightbulb_outline_rounded,
                                isLoading: _model.isProcessing,
                                onTap: () => _processDocument('simplify'),
                              ),
                              _AiActionButton(
                                label: 'أسئلة مراجعة',
                                icon: Icons.quiz_rounded,
                                isLoading: _model.isProcessing,
                                onTap: () => _processDocument('quiz'),
                              ),
                            ].divide(SizedBox(width: 12.0)),
                          ),
                          // AI result
                          if (_model.isProcessing)
                            Container(
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                borderRadius: BorderRadius.circular(24.0),
                                border: Border.all(
                                  color:
                                      FlutterFlowTheme.of(context).alternate,
                                  width: 1.0,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 20.0,
                                        height: 20.0,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                        ),
                                      ),
                                      SizedBox(width: 12.0),
                                      Text(
                                        'جارٍ المعالجة...',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.cairo(),
                                              letterSpacing: 0.0,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_model.aiResult != null && !_model.isProcessing)
                            Container(
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                borderRadius: BorderRadius.circular(24.0),
                                border: Border.all(
                                  color:
                                      FlutterFlowTheme.of(context).alternate,
                                  width: 1.0,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'نتيجة التحليل',
                                          style: FlutterFlowTheme.of(context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.cairo(
                                                    fontWeight:
                                                        FontWeight.bold),
                                                color: FlutterFlowTheme.of(
                                                        context)
                                                    .primary,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        SizedBox(width: 8.0),
                                        Icon(
                                          Icons.auto_awesome_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          size: 18.0,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.0),
                                    a11yLive(Text(
                                      _model.aiResult!,
                                      textAlign: TextAlign.end,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.cairo(),
                                            fontSize: FFAppState()
                                                        .readingFontSize <
                                                    24.0
                                                ? 24.0
                                                : FFAppState().readingFontSize,
                                            letterSpacing: 0.0,
                                            lineHeight: 1.6,
                                          ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                    ].divide(SizedBox(height: 32.0)),
                  ),
                ),
              ),
            ),
            // Font size slider
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
                shape: BoxShape.rectangle,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 1.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate,
                      shape: BoxShape.rectangle,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        32.0, 40.0, 32.0, 40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'حجم الخط',
                              style: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.cairo(),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    lineHeight: 1.4,
                                  ),
                            ),
                            Text(
                              'كبير',
                              style: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .override(
                                    font: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold),
                                    color:
                                        FlutterFlowTheme.of(context).primary,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    lineHeight: 1.4,
                                  ),
                            ),
                          ],
                        ),
                        wrapWithModel(
                          model: _model.sliderModel,
                          updateCallback: () => safeSetState(() {}),
                          child: SliderWidget(
                            label: 'حجم الخط',
                            labelPresent: true,
                            description: '',
                            descriptionPresent: false,
                            valuePercentage: FFAppState().readingFontSize,
                            valueLabel: '',
                            valueLabelPresent: false,
                            step: 0.0,
                            divisions: 0,
                            color: FlutterFlowTheme.of(context).primary,
                            variant: 'iOS',
                            disabled: false,
                            showTicks: true,
                          ),
                        ),
                      ].divide(SizedBox(height: 20.0)),
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

class _AiActionButton extends StatelessWidget {
  const _AiActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: a11yButton(
        enabled: !isLoading,
        child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Opacity(
          opacity: isLoading ? 0.5 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryContainer,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: FlutterFlowTheme.of(context).primary,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 24.0,
                  ),
                  SizedBox(height: 6.0),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          color: FlutterFlowTheme.of(context).primary,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
