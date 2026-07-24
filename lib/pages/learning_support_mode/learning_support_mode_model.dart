import '/components/button/button_widget.dart';
import '/components/mode_header/mode_header_widget.dart';
import '/components/slider/slider_widget.dart';
import '/components/text_block/text_block_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'learning_support_mode_widget.dart' show LearningSupportModeWidget;
import 'package:flutter/material.dart';
import 'dart:typed_data';

class LearningSupportModeModel
    extends FlutterFlowModel<LearningSupportModeWidget> {
  ///  Local state fields for this page.

  String? currentDocName = 'لم يُختر ملف بعد';
  String? pdfFilePath;
  Uint8List? pdfFileBytes;
  String? extractedText;
  String? aiResult;
  bool isProcessing = false;

  ///  State fields for stateful widgets in this page.

  late ModeHeaderModel modeHeaderModel;
  late ButtonModel buttonModel;
  late TextBlockModel textBlockModel;
  late SliderModel sliderModel;

  @override
  void initState(BuildContext context) {
    modeHeaderModel = createModel(context, () => ModeHeaderModel());
    buttonModel = createModel(context, () => ButtonModel());
    textBlockModel = createModel(context, () => TextBlockModel());
    sliderModel = createModel(context, () => SliderModel());
  }

  @override
  void dispose() {
    modeHeaderModel.dispose();
    buttonModel.dispose();
    textBlockModel.dispose();
    sliderModel.dispose();
  }
}
