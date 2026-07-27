// Reusable category-style UI helpers (docs/شادو_خطة_التكيف_الشاملة.md,
// Phase 4). Two small building blocks shared across all four modes:
//   - CollapsibleSecondaryActions: hides less-essential controls behind a
//     quiet "خيارات" toggle when StudentProfile.hidesSecondaryActions.
//   - permanentCaption: an always-visible caption under an action button,
//     for StudentProfile.showsPermanentTooltips.

import 'package:flutter/material.dart';

import '/theme.dart';

/// Renders [secondary] directly when [hidden] is false — unchanged from
/// before Phase 4. When [hidden] is true (neurodevelopmental / mild
/// cognitive), it's collapsed behind a "خيارات" toggle, starting collapsed.
class CollapsibleSecondaryActions extends StatefulWidget {
  const CollapsibleSecondaryActions({
    super.key,
    required this.hidden,
    required this.secondary,
  });

  final bool hidden;
  final Widget secondary;

  @override
  State<CollapsibleSecondaryActions> createState() =>
      _CollapsibleSecondaryActionsState();
}

class _CollapsibleSecondaryActionsState
    extends State<CollapsibleSecondaryActions> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.hidden) return widget.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.tune_rounded,
              size: 16,
              color: AppColors.mutedOnCream,
            ),
            label: Text(_expanded ? 'إخفاء الخيارات' : 'خيارات',
                style: AppText.label()),
          ),
        ),
        if (_expanded) widget.secondary,
      ],
    );
  }
}

/// A small always-visible caption under an action button.
Widget permanentCaption(String text) => Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: AppText.label(),
      ),
    );
