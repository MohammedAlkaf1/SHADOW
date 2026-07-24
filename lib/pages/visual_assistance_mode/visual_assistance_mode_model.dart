import '/components/feature_button/feature_button_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'visual_assistance_mode_widget.dart' show VisualAssistanceModeWidget;
import 'package:flutter/material.dart';
import 'dart:typed_data';

class VisualAssistanceModeModel
    extends FlutterFlowModel<VisualAssistanceModeWidget> {
  ///  Local state fields for this page.

  String? capturedImagePath;
  Uint8List? capturedImageBytes;
  String? analysisResult;
  bool isAnalyzing = false;
  bool isSpeaking = false;

  ///  State fields for stateful widgets in this page.

  // Model for FeatureButton.
  late FeatureButtonModel featureButtonModel1;
  // Model for FeatureButton.
  late FeatureButtonModel featureButtonModel2;

  @override
  void initState(BuildContext context) {
    featureButtonModel1 = createModel(context, () => FeatureButtonModel());
    featureButtonModel2 = createModel(context, () => FeatureButtonModel());
  }

  @override
  void dispose() {
    featureButtonModel1.dispose();
    featureButtonModel2.dispose();
  }
}
