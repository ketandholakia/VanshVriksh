import 'package:flutter/material.dart';

enum TreeViewMode { tree, fan }

class TreeFanModeToggle extends StatelessWidget {
  const TreeFanModeToggle({
    super.key,
    required this.selectedMode,
    required this.onTreeSelected,
    required this.onFanSelected,
  });

  final TreeViewMode selectedMode;
  final VoidCallback onTreeSelected;
  final VoidCallback onFanSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ToggleButtons(
      isSelected: [
        selectedMode == TreeViewMode.tree,
        selectedMode == TreeViewMode.fan,
      ],
      onPressed: (index) {
        if (index == 0) {
          onTreeSelected();
        } else {
          onFanSelected();
        }
      },
      borderRadius: BorderRadius.circular(12),
      constraints: const BoxConstraints(minHeight: 36, minWidth: 72),
      selectedColor: colorScheme.onPrimary,
      fillColor: colorScheme.primary,
      color: colorScheme.onSurfaceVariant,
      borderColor: colorScheme.outlineVariant,
      selectedBorderColor: colorScheme.primary,
      children: const [
        Tooltip(
          message: 'Family Tree',
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('Tree'),
          ),
        ),
        Tooltip(
          message: 'Fan Chart',
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('Fan'),
          ),
        ),
      ],
    );
  }
}
