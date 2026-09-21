import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/providers/backup_service_provider.dart';
import '../../services/backup_service.dart';
import '../settings/app_settings_provider.dart';

class BackupRestorePage extends ConsumerStatefulWidget {
  const BackupRestorePage({super.key});

  @override
  ConsumerState<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends ConsumerState<BackupRestorePage> {
  bool _isWorking = false;

  Future<String?> _promptForPassword({
    required String title,
    required String description,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(description),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _createBackup() async {
    final backupService = ref.read(backupServiceProvider);
    final encryptBackups = ref.read(backupEncryptProvider).value ?? true;
    final password = encryptBackups
        ? await _promptForPassword(
            title: 'Encrypt Backup',
            description:
                'Enter a password to encrypt this backup before exporting it.',
          )
        : null;
    if (encryptBackups && password == null) return;

    setState(() {
      _isWorking = true;
    });

    try {
      final backupFile = await backupService.createBackup(password: password);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup created: ${backupFile.path}')),
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupFile.path)],
          text: 'VanshVriksh backup file',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _createCloudBackup() async {
    final backupService = ref.read(backupServiceProvider);
    final encryptBackups = ref.read(backupEncryptProvider).value ?? true;
    final password = encryptBackups
        ? await _promptForPassword(
            title: 'Cloud Backup Password',
            description:
                'Enter a password to encrypt this backup before uploading it to Google Drive.',
          )
        : null;
    if (encryptBackups && password == null) return;

    setState(() {
      _isWorking = true;
    });

    try {
      final backupFile = await backupService.uploadBackupToGoogleDrive(
        password: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cloud backup uploaded: ${backupFile.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cloud backup failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Backup?'),
          content: const Text(
            'This will replace current VanshVriksh data with the selected backup. '
            'Please create a backup of current data before restoring. '
            'After restore, close and reopen the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Select Backup'),
            ),
          ],
        );
      },
    );

    if (shouldContinue != true) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'enc'],
      allowMultiple: false,
    );

    if (picked == null || picked.files.single.path == null) return;

    final file = File(picked.files.single.path!);
    final needsPassword = file.path.toLowerCase().endsWith('.enc');
    final password = needsPassword
        ? await _promptForPassword(
            title: 'Encrypted Backup',
            description:
                'Enter the password that was used to encrypt this backup.',
          )
        : null;
    if (needsPassword && password == null) return;

    setState(() {
      _isWorking = true;
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.restoreBackup(file, password: password);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Restore Completed'),
            content: const Text(
              'Backup restored successfully. Please close and reopen the app to reload the database.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _restoreFromCloud() async {
    final backupService = ref.read(backupServiceProvider);
    final password = await _promptForPassword(
      title: 'Restore Cloud Backup',
      description:
          'If the latest cloud backup is encrypted, enter the password to restore it.',
    );

    setState(() {
      _isWorking = true;
    });

    try {
      final backupFile = await backupService.restoreLatestFromGoogleDrive(
        password: password,
      );
      await backupService.restoreBackup(backupFile, password: password);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Cloud Restore Completed'),
            content: const Text(
              'Cloud backup restored successfully. Please close and reopen the app to reload the database.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cloud restore failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupService = ref.read(backupServiceProvider);
    final historyFuture = backupService.getBackupHistory();
    final lastBackupFuture = backupService.getLastBackup();
    final backupAutoAsync = ref.watch(backupAutoEnabledProvider);
    final backupFrequencyAsync = ref.watch(backupFrequencyProvider);
    final backupWifiOnlyAsync = ref.watch(backupWifiOnlyProvider);
    final backupEncryptAsync = ref.watch(backupEncryptProvider);
    final backupAutoEnabled = backupAutoAsync.value ?? backupAutoEnabledDefault;
    final selectedBackupFrequency =
        backupFrequencyAsync.value ?? backupFrequencyDefault;
    final backupWifiOnly = backupWifiOnlyAsync.value ?? backupWifiOnlyDefault;
    final backupEncryptEnabled =
        backupEncryptAsync.value ?? backupEncryptDefault;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _BackupHeaderCard(),
          const SizedBox(height: 12),
          FutureBuilder<BackupRecord?>(
            future: lastBackupFuture,
            builder: (context, snapshot) {
              final record = snapshot.data;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: const Text('Last Backup'),
                  subtitle: Text(
                    record == null
                        ? 'No backups recorded yet.'
                        : '${record.location == 'google_drive' ? 'Google Drive' : 'Local'} • ${record.fileName}\n${record.timestamp}${record.encrypted ? '\nEncrypted' : ''}',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backup Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.schedule_outlined),
                    title: const Text('Auto Backup'),
                    subtitle: const Text('Enable scheduled backups later.'),
                    value: backupAutoEnabled,
                    onChanged: backupAutoAsync.isLoading
                        ? null
                        : (value) => ref
                              .read(backupAutoEnabledProvider.notifier)
                              .setEnabled(value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<BackupFrequency>(
                    initialValue: selectedBackupFrequency,
                    decoration: const InputDecoration(
                      labelText: 'Backup Frequency',
                      prefixIcon: Icon(Icons.event_repeat_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: BackupFrequency.daily,
                        child: Text('Daily'),
                      ),
                      DropdownMenuItem(
                        value: BackupFrequency.weekly,
                        child: Text('Weekly'),
                      ),
                      DropdownMenuItem(
                        value: BackupFrequency.monthly,
                        child: Text('Monthly'),
                      ),
                    ],
                    onChanged: backupFrequencyAsync.isLoading
                        ? null
                        : (value) {
                            if (value == null) return;
                            ref
                                .read(backupFrequencyProvider.notifier)
                                .setFrequency(value);
                          },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.wifi_outlined),
                    title: const Text('Wi-Fi Only'),
                    subtitle: const Text(
                      'Use Wi-Fi when auto backup is added.',
                    ),
                    value: backupWifiOnly,
                    onChanged: backupWifiOnlyAsync.isLoading
                        ? null
                        : (value) => ref
                              .read(backupWifiOnlyProvider.notifier)
                              .setEnabled(value),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.lock_outline),
                    title: const Text('Encrypt Backup'),
                    subtitle: const Text(
                      'Protect backup files with a password.',
                    ),
                    value: backupEncryptEnabled,
                    onChanged: backupEncryptAsync.isLoading
                        ? null
                        : (value) => ref
                              .read(backupEncryptProvider.notifier)
                              .setEnabled(value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Local Backup'),
              subtitle: const Text(
                'Export database and profile photos into a ZIP backup file on this phone.',
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: !_isWorking,
              onTap: _isWorking ? null : _createBackup,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Cloud Backup'),
              subtitle: const Text('Upload your backup to Google Drive.'),
              trailing: const Icon(Icons.chevron_right),
              enabled: !_isWorking,
              onTap: _isWorking ? null : _createCloudBackup,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: const Text('Restore Local Backup'),
              subtitle: const Text('Import a VanshVriksh ZIP backup file.'),
              trailing: const Icon(Icons.chevron_right),
              enabled: !_isWorking,
              onTap: _isWorking ? null : _restoreBackup,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Restore from Cloud'),
              subtitle: const Text(
                'Download the latest backup from Google Drive and restore it.',
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: !_isWorking,
              onTap: _isWorking ? null : _restoreFromCloud,
            ),
          ),
          const SizedBox(height: 20),
          if (_isWorking) const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 20),
          FutureBuilder<List<BackupRecord>>(
            future: historyFuture,
            builder: (context, snapshot) {
              final history = snapshot.data ?? const [];
              if (history.isEmpty) {
                return const SizedBox.shrink();
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Backup History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...history
                          .take(5)
                          .map(
                            (record) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                record.location == 'google_drive'
                                    ? Icons.cloud_outlined
                                    : Icons.devices_outlined,
                              ),
                              title: Text(record.fileName),
                              subtitle: Text(
                                '${record.location} • ${record.timestamp}${record.encrypted ? ' • encrypted' : ''}',
                              ),
                              trailing: Text(record.status),
                            ),
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const _BackupWarningCard(),
        ],
      ),
    );
  }
}

class _BackupHeaderCard extends StatelessWidget {
  const _BackupHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              Icons.shield_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Keep Your Family Data Safe',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create regular backups and store them safely on Google Drive, email, or external storage.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupWarningCard extends StatelessWidget {
  const _BackupWarningCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Restore will overwrite current data. Always create a backup before restoring another backup file.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
