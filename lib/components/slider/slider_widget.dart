import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'slider_model.dart';
export 'slider_model.dart';

class SliderWidget extends StatefulWidget {
  const SliderWidget({
    super.key,
    String? label,
    bool? labelPresent,
    String? description,
    bool? descriptionPresent,
    double? valuePercentage,
    String? valueLabel,
    bool? valueLabelPresent,
    double? step,
    int? divisions,
    Color? color,
    String? variant,
    bool? disabled,
    bool? showTicks,
  })  : this.label = label ?? 'Font Size',
        this.labelPresent = labelPresent ?? true,
        this.description = description ?? '',
        this.descriptionPresent = descriptionPresent ?? false,
        this.valuePercentage = valuePercentage ?? 50.0,
        this.valueLabel = valueLabel ?? '',
        this.valueLabelPresent = valueLabelPresent ?? false,
        this.step = step ?? 0.0,
        this.divisions = divisions ?? 0,
        this.color = color ?? const Color(0x00000000),
        this.variant = variant ?? 'iOS',
        this.disabled = disabled ?? false,
        this.showTicks = showTicks ?? true;

  final String label;
  final bool labelPresent;
  final String description;
  final bool descriptionPresent;
  final double valuePercentage;
  final String valueLabel;
  final bool valueLabelPresent;
  final double step;
  final int divisions;
  final Color color;
  final String variant;
  final bool disabled;
  final bool showTicks;

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  late SliderModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SliderModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget!.disabled ? 0.55 : 1.0,
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (valueOrDefault<bool>(
                  widget!.labelPresent,
                  true,
                ))
                  Expanded(
                    flex: 1,
                    child: Text(
                      valueOrDefault<String>(
                        widget!.label,
                        'Font Size',
                      ),
                      maxLines: 1,
                      style: FlutterFlowTheme.of(context).labelLarge.override(
                            font: GoogleFonts.cairo(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelLarge
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelLarge
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (valueOrDefault<bool>(
                  widget!.valueLabelPresent,
                  false,
                ))
                  Text(
                    widget!.valueLabel,
                    maxLines: 1,
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.cairo(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                          lineHeight: 1.4,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ].divide(SizedBox(width: 20.0)),
            ),
            Container(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                    valueOrDefault<double>(
                      widget!.variant == 'iOS' ? 0.0 : 0.0,
                      0.0,
                    ),
                    valueOrDefault<double>(
                      widget!.variant == 'iOS' ? 0.0 : 12.0,
                      0.0,
                    ),
                    valueOrDefault<double>(
                      widget!.variant == 'iOS' ? 0.0 : 0.0,
                      0.0,
                    ),
                    valueOrDefault<double>(
                      widget!.variant == 'iOS' ? 0.0 : 12.0,
                      0.0,
                    )),
                child: Container(
                  child: Slider(
                    activeColor: valueOrDefault<Color>(
                      widget!.color,
                      FlutterFlowTheme.of(context).primary,
                    ),
                    inactiveColor: FlutterFlowTheme.of(context).alternate,
                    min: 0.0,
                    max: 100.0,
                    value: _model.sliderValue ??= valueOrDefault<double>(
                      widget!.valuePercentage,
                      50.0,
                    ),
                    onChanged: (newValue) {
                      newValue = double.parse(newValue.toStringAsFixed(2));
                      safeSetState(() => _model.sliderValue = newValue);
                    },
                  ),
                ),
              ),
            ),
            if (valueOrDefault<bool>(
              widget!.descriptionPresent,
              false,
            ))
              Text(
                widget!.description,
                maxLines: 2,
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.cairo(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodySmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      lineHeight: 1.5,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
          ].divide(SizedBox(height: 6.0)),
        ),
      ),
    );
  }
}
