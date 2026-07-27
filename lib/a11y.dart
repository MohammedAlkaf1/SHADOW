// Accessibility helpers used across the app.
//
// Shadow is an accessibility product, so every interactive control must be
// reachable and correctly announced by screen readers (Android TalkBack). These
// small wrappers keep that consistent without restructuring the FlutterFlow UI.

import 'package:flutter/material.dart';

import '/theme.dart';

/// Wraps an interactive control so a screen reader announces it as one button.
///
/// - Pass [label] for icon-only controls (the icon carries no text).
/// - Omit [label] for controls that already contain descriptive text; the
///   child's text supplies the name and [MergeSemantics] folds it, the tap
///   action, and the button role into a single focusable node.
///
/// The underlying InkWell/GestureDetector/IconButton keeps its tap action, so
/// TalkBack "double-tap to activate" works.
Widget a11yButton({
  String? label,
  String? hint,
  bool enabled = true,
  required Widget child,
}) {
  return MergeSemantics(
    child: Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      child: child,
    ),
  );
}

/// Marks content that should be spoken by the screen reader whenever it changes
/// — e.g. an AI analysis result or a recognised voice command appearing.
Widget a11yLive(Widget child) =>
    Semantics(liveRegion: true, container: true, child: child);

/// Back-navigation chevron that points the reading-correct way: left in LTR,
/// right in RTL. Returns a plain [Icon] (not a Transform) so callers such as
/// FlutterFlowIconButton — whose `icon` field is typed `Icon` — accept it; we
/// pick the direction-correct glyph rather than flipping a widget.
Icon appBackIcon(BuildContext context,
    {Color color = AppColors.onCream, double size = 22}) {
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  return Icon(
    isRtl ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
    color: color,
    size: size,
  );
}
