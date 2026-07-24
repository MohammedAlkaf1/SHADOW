import '/components/status_badge/status_badge_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import 'deaf_mode_transcription_widget.dart' show DeafModeTranscriptionWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DeafModeTranscriptionModel
    extends FlutterFlowModel<DeafModeTranscriptionWidget> {
  ///  Local state fields for this page.

  String? liveText =
      'أهلاً بكم في جامعة الملك سعود. اليوم سنتحدث عن أهمية تقنيات الوصول الشامل للطلاب ذوي الإعاقة وكيف يمكن للذكاء الاصطناعي تسهيل حياتنا الجامعية...';

  String? sessionTitle = 'محاضرة الذكاء الاصطناعي - ١٠:٤٥ ص';

  ///  State fields for stateful widgets in this page.

  // Model for StatusBadge.
  late StatusBadgeModel statusBadgeModel;

  @override
  void initState(BuildContext context) {
    statusBadgeModel = createModel(context, () => StatusBadgeModel());
  }

  @override
  void dispose() {
    statusBadgeModel.dispose();
  }
}
