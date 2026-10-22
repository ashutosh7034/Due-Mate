import 'package:flutter/material.dart';

import '../../tasks/quick_add_sheet.dart';

/// The primary "add task" affordance.
///
/// Opens the quick-add sheet (natural-language entry) rather than the full
/// editor, because speed of capture is the product's core promise.
class ShellFab extends StatelessWidget {
  const ShellFab({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: FloatingActionButton.extended(
        onPressed: visible ? () => QuickAddSheet.show(context) : null,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add task'),
      ),
    );
  }
}
