import 'package:flutter/material.dart';

import '../../app/brand_background.dart';
import '../../core/widgets/empty_state.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: BrandWatermark(
              alignment: Alignment.center,
              opacity: 0.04,
              scale: 1.05,
              padding: EdgeInsets.zero,
            ),
          ),
          const EmptyState(
            title: 'Backup and restore',
            message:
                'Import and export support will be added here so family data stays portable.',
            icon: Icons.backup_outlined,
          ),
        ],
      ),
    );
  }
}
