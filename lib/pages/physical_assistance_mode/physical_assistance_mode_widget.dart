import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'physical_assistance_mode_model.dart';
export 'physical_assistance_mode_model.dart';

class PhysicalAssistanceModeWidget extends StatefulWidget {
  const PhysicalAssistanceModeWidget({super.key});

  static String routeName = 'PhysicalAssistanceMode';
  static String routePath = '/physicalAssistanceMode';

  @override
  State<PhysicalAssistanceModeWidget> createState() =>
      _PhysicalAssistanceModeWidgetState();
}

class _PhysicalAssistanceModeWidgetState
    extends State<PhysicalAssistanceModeWidget> {
  late PhysicalAssistanceModeModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PhysicalAssistanceModeModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _handleVoiceCommand() async {
    safeSetState(() => _model.isListeningForCommand = true);
    final command = await actions.listenForVoiceCommand();
    safeSetState(() {
      _model.isListeningForCommand = false;
      if (command.isNotEmpty) _model.lastVoiceCommand = command;
    });

    if (command.isEmpty) return;
    if (command.contains('الصمم') || command.contains('صمم')) {
      context.pushNamed('DeafModeTranscription');
    } else if (command.contains('البصري') || command.contains('بصري')) {
      context.pushNamed('VisualAssistanceMode');
    } else if (command.contains('التعلم') || command.contains('تعلم')) {
      context.pushNamed('LearningSupportMode');
    } else if (command.contains('ارجع') ||
        command.contains('رجع') ||
        command.contains('رئيسي')) {
      context.pop();
    } else if (command.contains('اتصل') || command.contains('مساعد')) {
      _showEmergencyDialog();
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        title: Text(
          'مساعدة طارئة',
          textAlign: TextAlign.end,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20.0),
        ),
        content: Text(
          'هل تريد الاتصال بالأمن الجامعي؟',
          textAlign: TextAlign.end,
          style: GoogleFonts.cairo(fontSize: 16.0),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child:
                Text('اتصال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commands = [
      (label: 'افتح وضع الصمم', icon: Icons.hearing_rounded),
      (label: 'افتح وضع البصرية', icon: Icons.visibility_rounded),
      (label: 'افتح وضع التعلم', icon: Icons.psychology_rounded),
      (label: 'ارجع للرئيسية', icon: Icons.home_rounded),
      (label: 'اتصل بالمساعد', icon: Icons.phone_rounded),
    ];

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEmergencyDialog,
        backgroundColor: FlutterFlowTheme.of(context).error,
        icon: const Icon(Icons.emergency_share_rounded, color: Colors.white),
        label: Text(
          '🆘 مساعدة طارئة',
          style:
              GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(32.0, 20.0, 32.0, 20.0),
                  child: Row(
                    children: [
                      FlutterFlowIconButton(
                        borderRadius: 8.0,
                        buttonSize: 40.0,
                        fillColor: Colors.transparent,
                        icon: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: FlutterFlowTheme.of(context).primaryText,
                          size: 24.0,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          'التحكم بالصوت',
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
                    ].divide(SizedBox(width: 20.0)),
                  ),
                ),
                Container(
                  height: 1.0,
                  color: FlutterFlowTheme.of(context).alternate,
                ),
              ],
            ),
          ),
          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Voice command display
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 80.0),
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: _model.isListeningForCommand
                            ? FlutterFlowTheme.of(context).primary
                            : FlutterFlowTheme.of(context).alternate,
                        width: 2.0,
                      ),
                    ),
                    child: Text(
                      _model.isListeningForCommand
                          ? '🎙 جارٍ الاستماع...'
                          : (_model.lastVoiceCommand ??
                              'انتظار الأمر الصوتي...'),
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context)
                          .titleMedium
                          .override(
                            font: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold),
                            color: _model.isListeningForCommand
                                ? FlutterFlowTheme.of(context).primary
                                : FlutterFlowTheme.of(context)
                                    .secondaryText,
                            letterSpacing: 0.0,
                            lineHeight: 1.4,
                          ),
                    ),
                  ),
                  SizedBox(height: 40.0),
                  // Big mic button
                  GestureDetector(
                    onTap: _model.isListeningForCommand
                        ? null
                        : _handleVoiceCommand,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 140.0,
                      height: 140.0,
                      decoration: BoxDecoration(
                        color: _model.isListeningForCommand
                            ? FlutterFlowTheme.of(context)
                                .success
                                .withOpacity(0.2)
                            : FlutterFlowTheme.of(context).success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: FlutterFlowTheme.of(context)
                                .success
                                .withOpacity(
                                    _model.isListeningForCommand ? 0.6 : 0.3),
                            blurRadius: 24.0,
                            spreadRadius:
                                _model.isListeningForCommand ? 10.0 : 0.0,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _model.isListeningForCommand
                          ? SizedBox(
                              width: 52.0,
                              height: 52.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                                color:
                                    FlutterFlowTheme.of(context).success,
                              ),
                            )
                          : const Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 64.0,
                            ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    _model.isListeningForCommand
                        ? 'جارٍ الاستماع...'
                        : 'اضغط وتكلم',
                    style: FlutterFlowTheme.of(context).titleSmall.override(
                          font: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          color: _model.isListeningForCommand
                              ? FlutterFlowTheme.of(context).success
                              : FlutterFlowTheme.of(context).primaryText,
                          letterSpacing: 0.0,
                        ),
                  ),
                  SizedBox(height: 40.0),
                  // Commands section title
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      'الأوامر المدعومة',
                      style: FlutterFlowTheme.of(context)
                          .titleSmall
                          .override(
                            font: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  // Command cards
                  ...commands.map(
                    (cmd) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 18.0),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .primaryContainer,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '"${cmd.label}"',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w600),
                                    letterSpacing: 0.0,
                                  ),
                            ),
                            SizedBox(width: 12.0),
                            Icon(
                              cmd.icon,
                              color:
                                  FlutterFlowTheme.of(context).primary,
                              size: 22.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
