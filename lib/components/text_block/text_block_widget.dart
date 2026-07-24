import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'text_block_model.dart';
export 'text_block_model.dart';

class TextBlockWidget extends StatefulWidget {
  const TextBlockWidget({
    super.key,
    double? size,
    this.content,
  }) : this.size = size ?? 0.0;

  final double size;
  final String? content;

  @override
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget> {
  late TextBlockModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TextBlockModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(24.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Container(
          child: Text(
            widget.content ??
                'هذا نص تجريبي لمحاكاة محتوى ملف PDF. يمكن للمستخدم تغيير حجم هذا الخط باستخدام الشريط المنزلق في الأسفل لتحسين تجربة القراءة والتعلم.',
            textAlign: TextAlign.end,
            style: FlutterFlowTheme.of(context).bodyLarge.override(
                  font: GoogleFonts.cairo(
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                    fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                  ),
                  fontSize: valueOrDefault<double>(
                    widget!.size,
                    0.0,
                  ),
                  letterSpacing: 0.0,
                  fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                  lineHeight: 1.6,
                ),
          ),
        ),
      ),
    );
  }
}
