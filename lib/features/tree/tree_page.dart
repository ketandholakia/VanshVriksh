import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

class TreePage extends StatelessWidget {
  const TreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tree')),
      body: const EmptyState(
        title: 'Tree view coming next',
        message:
            'This page will become the interactive family tree with zoom, pan, and centered root selection.',
        icon: Icons.account_tree_outlined,
      ),
    );
  }
}
