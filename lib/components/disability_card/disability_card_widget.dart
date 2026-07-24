import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'disability_card_model.dart';
export 'disability_card_model.dart';

class DisabilityCardWidget extends StatefulWidget {
  const DisabilityCardWidget({
    super.key,
    bool? selected,
    Color? colorBg,
    this.icon,
    Color? colorFg,
    String? label,
    this.description,
  })  : this.selected = selected ?? false,
        this.colorBg = colorBg ?? const Color(0xFFE8F5E9),
        this.colorFg = colorFg ?? const Color(0x00000000),
        this.label = label ?? 'صمم / ضعف سمع';

  final bool selected;
  final Color colorBg;
  final Widget? icon;
  final Color colorFg;
  final String label;
  final String? description;

  @override
  State<DisabilityCardWidget> createState() => _DisabilityCardWidgetState();
}

class _DisabilityCardWidgetState extends State<DisabilityCardWidget> {
  late DisabilityCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DisabilityCardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: widget.selected
            ? FlutterFlowTheme.of(context).primary
            : FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(32.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary
              .withOpacity(widget.selected ? 1.0 : 0.35),
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(14.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: widget.selected
                    ? FlutterFlowTheme.of(context).secondary
                    : widget.colorBg,
                borderRadius: BorderRadius.circular(9999.0),
              ),
              alignment: AlignmentDirectional(0.0, 0.0),
              child: IconTheme(
                data: IconThemeData(
                  color: widget.selected
                      ? FlutterFlowTheme.of(context).onPrimary
                      : null,
                ),
                child: widget.icon!,
              ),
            ),
            Text(
              valueOrDefault<String>(widget.label, 'صمم / ضعف سمع'),
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    font: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    color: widget.selected
                        ? FlutterFlowTheme.of(context).onPrimary
                        : FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                    lineHeight: 1.4,
                  ),
            ),
            if (widget.description != null)
              Text(
                widget.description!,
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.cairo(),
                      color: widget.selected
                          ? FlutterFlowTheme.of(context).onPrimary.withOpacity(0.75)
                          : FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0.0,
                      lineHeight: 1.4,
                    ),
              ),
          ].divide(SizedBox(height: 10.0)),
        ),
      ),
    );
  }
}
