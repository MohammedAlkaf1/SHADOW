import '/components/disability_card/disability_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'welcome_selection_model.dart';
export 'welcome_selection_model.dart';

class WelcomeSelectionWidget extends StatefulWidget {
  const WelcomeSelectionWidget({super.key});

  static String routeName = 'WelcomeSelection';
  static String routePath = '/welcomeSelection';

  @override
  State<WelcomeSelectionWidget> createState() => _WelcomeSelectionWidgetState();
}

class _WelcomeSelectionWidgetState extends State<WelcomeSelectionWidget> {
  late WelcomeSelectionModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WelcomeSelectionModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
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
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate row height dynamically to prevent overflow on any screen.
              // Fixed overhead: header≈80 + gap12 + gap16 + gap16 + footer≈24 + padV40
              const fixedOverhead = 80.0 + 12.0 + 16.0 + 16.0 + 24.0 + 40.0;
              final rowH = ((constraints.maxHeight - fixedOverhead - 16.0) / 2)
                  .clamp(110.0, 210.0);

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header — compact horizontal layout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: const Color(0xFF003651).withOpacity(0.15),
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'ش',
                            style: GoogleFonts.cairo(
                              fontSize: 26.0,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFC16325),
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'شادو — Shadow',
                              style: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .override(
                                    font: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w900),
                                    color: FlutterFlowTheme.of(context).primary,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w900,
                                    lineHeight: 1.2,
                                  ),
                            ),
                            Text(
                              'مرافقك الأكاديمي الذكي',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.cairo(),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    lineHeight: 1.3,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    // Row 1
                    SizedBox(
                      height: rowH,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () => context.pushNamed(
                                  DeafModeTranscriptionWidget.routeName),
                              child: wrapWithModel(
                                model: _model.disabilityCardModel1,
                                updateCallback: () => safeSetState(() {}),
                                child: DisabilityCardWidget(
                                  selected: false,
                                  colorBg: const Color(0xFFF5F0E8),
                                  icon: const Icon(Icons.hearing_rounded,
                                      size: 28.0,
                                      color: Color(0xFF003651)),
                                  colorFg: const Color(0xFF003651),
                                  label: 'صمم / ضعف سمع',
                                  description: 'ترجمة فورية للمحاضرات',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () => context.pushNamed(
                                  VisualAssistanceModeWidget.routeName),
                              child: wrapWithModel(
                                model: _model.disabilityCardModel2,
                                updateCallback: () => safeSetState(() {}),
                                child: DisabilityCardWidget(
                                  selected: false,
                                  colorBg: const Color(0xFFF5F0E8),
                                  icon: const Icon(Icons.visibility_rounded,
                                      size: 28.0,
                                      color: Color(0xFFC16325)),
                                  colorFg: const Color(0xFFC16325),
                                  label: 'إعاقة بصرية',
                                  description: 'وصف المحيط والنصوص',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Row 2
                    SizedBox(
                      height: rowH,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () => context.pushNamed(
                                  LearningSupportModeWidget.routeName),
                              child: wrapWithModel(
                                model: _model.disabilityCardModel3,
                                updateCallback: () => safeSetState(() {}),
                                child: DisabilityCardWidget(
                                  selected: false,
                                  colorBg: const Color(0xFFF5F0E8),
                                  icon: const Icon(Icons.psychology_rounded,
                                      size: 28.0,
                                      color: Color(0xFF003651)),
                                  colorFg: const Color(0xFF003651),
                                  label: 'صعوبات تعلم',
                                  description: 'تبسيط المواد الدراسية',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () => context.pushNamed(
                                  PhysicalAssistanceModeWidget.routeName),
                              child: wrapWithModel(
                                model: _model.disabilityCardModel4,
                                updateCallback: () => safeSetState(() {}),
                                child: DisabilityCardWidget(
                                  selected: false,
                                  colorBg: const Color(0xFFF5F0E8),
                                  icon: const Icon(
                                      Icons.accessible_forward_rounded,
                                      size: 28.0,
                                      color: Color(0xFFC16325)),
                                  colorFg: const Color(0xFFC16325),
                                  label: 'إعاقة حركية',
                                  description: 'التحكم بالصوت',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'هل تحتاج إلى مساعدة؟',
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    font: GoogleFonts.cairo(),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    lineHeight: 1.5,
                                  ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'اتصل بنا',
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    font: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold),
                                    color:
                                        FlutterFlowTheme.of(context).primary,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    lineHeight: 1.5,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
