import '/components/disability_card/disability_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'welcome_selection_widget.dart' show WelcomeSelectionWidget;
import 'package:flutter/material.dart';

class WelcomeSelectionModel extends FlutterFlowModel<WelcomeSelectionWidget> {
  late DisabilityCardModel disabilityCardModel1;
  late DisabilityCardModel disabilityCardModel2;
  late DisabilityCardModel disabilityCardModel3;
  late DisabilityCardModel disabilityCardModel4;

  @override
  void initState(BuildContext context) {
    disabilityCardModel1 = createModel(context, () => DisabilityCardModel());
    disabilityCardModel2 = createModel(context, () => DisabilityCardModel());
    disabilityCardModel3 = createModel(context, () => DisabilityCardModel());
    disabilityCardModel4 = createModel(context, () => DisabilityCardModel());
  }

  @override
  void dispose() {
    disabilityCardModel1.dispose();
    disabilityCardModel2.dispose();
    disabilityCardModel3.dispose();
    disabilityCardModel4.dispose();
  }
}
