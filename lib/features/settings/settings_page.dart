import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand_background.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/genealogy_person_extensions.dart';
import '../people/people_providers.dart';
import '../gedcom/gedcom_import_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'app_settings_provider.dart';
import 'fan_chart_settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fanDepthAsync = ref.watch(fanChartAncestorGenerationsProvider);
    final selectedFanDepth =
        fanDepthAsync.value ?? fanChartAncestorGenerationsDefault;
    final landingViewAsync = ref.watch(appLandingViewProvider);
    final selectedLandingView = landingViewAsync.value ?? appLandingViewDefault;
    final dateFormatAsync = ref.watch(dateDisplayFormatProvider);
    final selectedDateFormat =
        dateFormatAsync.value ?? dateDisplayFormatDefault;
    final labelStyleAsync = ref.watch(relationshipLabelStyleProvider);
    final selectedLabelStyle =
        labelStyleAsync.value ?? relationshipLabelStyleDefault;
    final themeModeAsync = ref.watch(appThemeModeProvider);
    final selectedThemeMode = themeModeAsync.value ?? appThemeModeDefault;
    final backupAutoAsync = ref.watch(backupAutoEnabledProvider);
    final selectedBackupAuto = backupAutoAsync.value ?? backupAutoEnabledDefault;
    final backupFrequencyAsync = ref.watch(backupFrequencyProvider);
    final selectedBackupFrequency =
        backupFrequencyAsync.value ?? backupFrequencyDefault;
    final backupWifiOnlyAsync = ref.watch(backupWifiOnlyProvider);
    final selectedBackupWifiOnly =
        backupWifiOnlyAsync.value ?? backupWifiOnlyDefault;
    final backupEncryptAsync = ref.watch(backupEncryptProvider);
    final selectedBackupEncrypt =
        backupEncryptAsync.value ?? backupEncryptDefault;
    final treeDensityAsync = ref.watch(treeCardDensityProvider);
    final selectedTreeDensity =
        treeDensityAsync.value ?? treeCardDensityDefault;
    final lineThicknessAsync = ref.watch(treeLineThicknessProvider);
    final selectedLineThickness =
        lineThicknessAsync.value ?? treeLineThicknessDefault;
    final connectorPaletteAsync = ref.watch(treeConnectorPaletteProvider);
    final selectedConnectorPalette =
        connectorPaletteAsync.value ?? treeConnectorPaletteDefault;
    final spousePaletteAsync = ref.watch(treeSpouseConnectorPaletteProvider);
    final selectedSpousePalette =
        spousePaletteAsync.value ?? treeSpouseConnectorPaletteDefault;
    final childPaletteAsync = ref.watch(treeChildConnectorPaletteProvider);
    final selectedChildPalette =
        childPaletteAsync.value ?? treeChildConnectorPaletteDefault;
    final rememberRootAsync = ref.watch(rememberLastRootPersonProvider);
    final rememberRootEnabled =
        rememberRootAsync.value ?? rememberLastRootPersonDefault;
    final hideYearsAsync = ref.watch(hideYearsForLivingProvider);
    final hideYearsForLiving =
        hideYearsAsync.value ?? hideYearsForLivingDefault;
    final peopleAsync = ref.watch(peopleListProvider);
    final defaultRootAsync = ref.watch(defaultRootPersonIdProvider);
    final selectedDefaultRootId = defaultRootAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: BrandWatermark(
              alignment: Alignment.topRight,
              opacity: 0.03,
              scale: 1.08,
              padding: EdgeInsets.only(top: 12, right: 8),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _AppInfoCard(),
              const SizedBox(height: 16),
              const Text(
                'Data & Backup',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Backup & Restore'),
                      subtitle: const Text('Export or restore your family tree data.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings/backup'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined),
                      title: const Text('Import GEDCOM 5.5.1'),
                      subtitle: const Text('Import genealogy records from a .ged file.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _importGedcom(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cloud_sync_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Backup Preferences',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Auto Backup'),
                        subtitle: const Text('Enable scheduled backups later.'),
                        value: selectedBackupAuto,
                        onChanged: backupAutoAsync.isLoading
                            ? null
                            : (value) {
                                ref
                                    .read(backupAutoEnabledProvider.notifier)
                                    .setEnabled(value);
                              },
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
                        title: const Text('Wi-Fi Only'),
                        subtitle: const Text('Prefer Wi-Fi for cloud backups.'),
                        value: selectedBackupWifiOnly,
                        onChanged: backupWifiOnlyAsync.isLoading
                            ? null
                            : (value) {
                                ref
                                    .read(backupWifiOnlyProvider.notifier)
                                    .setEnabled(value);
                              },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Encrypt Backup'),
                        subtitle: const Text('Protect backups with a password.'),
                        value: selectedBackupEncrypt,
                        onChanged: backupEncryptAsync.isLoading
                            ? null
                            : (value) {
                                ref
                                    .read(backupEncryptProvider.notifier)
                                    .setEnabled(value);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Marked Duplicates'),
                  subtitle: const Text(
                    'Review pairs you manually flagged as possible duplicates.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/duplicates/marked'),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: const Text('Integrity Check'),
                  subtitle: const Text(
                    'Scan for impossible relationships and circular links.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/integrity'),
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Backup Reminder'),
                  subtitle: const Text(
                    'Coming soon: remind me to backup regularly.',
                  ),
                  trailing: const Chip(label: Text('Soon')),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup reminder will be added later.'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Import / Export',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('GEDCOM Import'),
                  subtitle: const Text(
                    'Coming soon: import .ged genealogy files.',
                  ),
                  trailing: const Chip(label: Text('Soon')),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('GEDCOM import will be added later.'),
                      ),
                    );
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('GEDCOM Export'),
                  subtitle: const Text(
                    'Coming soon: export your family tree as .ged file.',
                  ),
                  trailing: const Chip(label: Text('Soon')),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('GEDCOM export will be added later.'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.brightness_auto_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Theme Mode',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose how the app should match your device theme.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AppThemeMode>(
                        initialValue: selectedThemeMode,
                        decoration: const InputDecoration(
                          labelText: 'App theme',
                          prefixIcon: Icon(Icons.palette_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: AppThemeMode.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: AppThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: AppThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                        onChanged: themeModeAsync.isLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                ref
                                    .read(appThemeModeProvider.notifier)
                                    .setMode(value);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.route_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Default Tree View',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Used when you tap Tree in the bottom navigation.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AppLandingView>(
                        initialValue: selectedLandingView,
                        decoration: const InputDecoration(
                          labelText: 'Tree button opens',
                          prefixIcon: Icon(Icons.switch_left_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: AppLandingView.tree,
                            child: Text('Tree'),
                          ),
                          DropdownMenuItem(
                            value: AppLandingView.fan,
                            child: Text('Fan Chart'),
                          ),
                        ],
                        onChanged: landingViewAsync.isLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                ref
                                    .read(appLandingViewProvider.notifier)
                                    .setLandingView(value);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.person_pin_outlined),
                  title: const Text('Remember Last Root Person'),
                  subtitle: const Text(
                    'Reopen Tree and Fan Chart from the last person you selected.',
                  ),
                  value: rememberRootEnabled,
                  onChanged: rememberRootAsync.isLoading
                      ? null
                      : (value) {
                          ref
                              .read(rememberLastRootPersonProvider.notifier)
                              .setEnabled(value);
                        },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.person_pin_circle_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Default Root Person',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Used if no remembered root exists when opening Tree or Fan Chart.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      peopleAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (error, stackTrace) => Text(
                          'Unable to load people for default root selection: $error',
                        ),
                        data: (people) {
                          return DropdownButtonFormField<String?>(
                            initialValue: selectedDefaultRootId,
                            decoration: const InputDecoration(
                              labelText: 'Default root person',
                              prefixIcon: Icon(Icons.account_tree_outlined),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No default'),
                              ),
                              ...people.map(
                                (person) => DropdownMenuItem<String?>(
                                  value: person.id,
                                  child: Text(person.fullName),
                                ),
                              ),
                            ],
                            onChanged: defaultRootAsync.isLoading
                                ? null
                                : (value) {
                                    ref
                                        .read(
                                          defaultRootPersonIdProvider.notifier,
                                        )
                                        .setPersonId(value);
                                  },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.zoom_out_map_outlined),
                  title: const Text('Zoom / Fit On Load'),
                  subtitle: const Text(
                    'Fit Tree and Fan Chart to the screen when they open.',
                  ),
                  value:
                      ref.watch(zoomOnLoadProvider).value ?? zoomOnLoadDefault,
                  onChanged: ref.watch(zoomOnLoadProvider).isLoading
                      ? null
                      : (value) {
                          ref
                              .read(zoomOnLoadProvider.notifier)
                              .setEnabled(value);
                        },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.space_dashboard_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tree / Fan Card Spacing',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Controls how spread out the relationship cards are in Tree and Fan Chart.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TreeCardSpacing>(
                        initialValue:
                            ref.watch(treeCardSpacingProvider).value ??
                            treeCardSpacingDefault,
                        decoration: const InputDecoration(
                          labelText: 'Spacing',
                          prefixIcon: Icon(Icons.tune_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TreeCardSpacing.compact,
                            child: Text('Compact'),
                          ),
                          DropdownMenuItem(
                            value: TreeCardSpacing.normal,
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(
                            value: TreeCardSpacing.spacious,
                            child: Text('Spacious'),
                          ),
                        ],
                        onChanged: ref.watch(treeCardSpacingProvider).isLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                ref
                                    .read(treeCardSpacingProvider.notifier)
                                    .setSpacing(value);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: const Text('Reset Tree State'),
                  subtitle: const Text(
                    'Clear saved branch expansion state for the genealogy tree.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await resetGenealogyTreeState(ref);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tree state reset.')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.palette_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Connector Colors',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Customize branch, spouse, and child accents in the genealogy tree.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<TreeConnectorPalette>(
                        initialValue: selectedConnectorPalette,
                        decoration: const InputDecoration(
                          labelText: 'Branch palette',
                          prefixIcon: Icon(Icons.account_tree_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TreeConnectorPalette.classic,
                            child: Text('Classic'),
                          ),
                          DropdownMenuItem(
                            value: TreeConnectorPalette.forest,
                            child: Text('Forest'),
                          ),
                          DropdownMenuItem(
                            value: TreeConnectorPalette.ocean,
                            child: Text('Ocean'),
                          ),
                          DropdownMenuItem(
                            value: TreeConnectorPalette.sunset,
                            child: Text('Sunset'),
                          ),
                        ],
                        onChanged: connectorPaletteAsync.isLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                ref
                                    .read(treeConnectorPaletteProvider.notifier)
                                    .setPalette(value);
                              },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TreeConnectorPalette>(
                              initialValue: selectedSpousePalette,
                              decoration: const InputDecoration(
                                labelText: 'Spouse palette',
                                prefixIcon: Icon(Icons.favorite_border),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: TreeConnectorPalette.classic,
                                  child: Text('Classic'),
                                ),
                                DropdownMenuItem(
                                  value: TreeConnectorPalette.forest,
                                  child: Text('Forest'),
                                ),
                                DropdownMenuItem(
                                  value: TreeConnectorPalette.ocean,
                                  child: Text('Ocean'),
                                ),
                                DropdownMenuItem(
                                  value: TreeConnectorPalette.sunset,
                                  child: Text('Sunset'),
                                ),
                              ],
                              onChanged: spousePaletteAsync.isLoading
                                  ? null
                                  : (value) {
                                      if (value == null) return;
                                      ref
                                          .read(
                                            treeSpouseConnectorPaletteProvider
                                                .notifier,
                                          )
                                          .setPalette(value);
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<TreeConnectorPalette>(
                              initialValue: selectedChildPalette,
                              decoration: const InputDecoration(
                                labelText: 'Child palette',
                                prefixIcon: Icon(Icons.child_care),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: TreeConnectorPalette.classic,
                                  child: Text('Classic'),
                                ),
                                DropdownMenuItem(
                                  value: TreeConnectorPalette.forest,
                                  child: Text('Forest'),
                                ),
                                DropdownMenuItem(
                                  value: TreeConnectorPalette.ocean,
                                  child: Text('Ocean'),
                                ),
                                DropdownMenuItem(
                                  value: TreeConnectorPalette.sunset,
                                  child: Text('Sunset'),
                                ),
                              ],
                              onChanged: childPaletteAsync.isLoading
                                  ? null
                                  : (value) {
                                      if (value == null) return;
                                      ref
                                          .read(
                                            treeChildConnectorPaletteProvider
                                                .notifier,
                                          )
                                          .setPalette(value);
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.straighten_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tree Line Thickness',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Controls how bold the connector lines appear in Tree and Fan Chart.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TreeLineThickness>(
                        initialValue: selectedLineThickness,
                        decoration: const InputDecoration(
                          labelText: 'Line thickness',
                          prefixIcon: Icon(Icons.line_weight_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TreeLineThickness.thin,
                            child: Text('Thin'),
                          ),
                          DropdownMenuItem(
                            value: TreeLineThickness.normal,
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(
                            value: TreeLineThickness.thick,
                            child: Text('Thick'),
                          ),
                        ],
                        onChanged: lineThicknessAsync.isLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                ref
                                    .read(treeLineThicknessProvider.notifier)
                                    .setThickness(value);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.crop_free_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Photo Crop Mode',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose how profile photos are drawn inside circular avatars.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<PersonPhotoFitMode>(
                        initialValue:
                            ref.watch(personPhotoFitModeProvider).value ??
                            personPhotoFitModeDefault,
                        decoration: const InputDecoration(
                          labelText: 'Photo mode',
                          prefixIcon: Icon(
                            Icons.photo_size_select_actual_outlined,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: PersonPhotoFitMode.cover,
                            child: Text('Crop to fill'),
                          ),
                          DropdownMenuItem(
                            value: PersonPhotoFitMode.contain,
                            child: Text('Fit inside'),
                          ),
                        ],
                        onChanged:
                            ref.watch(personPhotoFitModeProvider).isLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                ref
                                    .read(personPhotoFitModeProvider.notifier)
                                    .setMode(value);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.view_comfy_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tree / Fan Card Density',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Changes card size and font density in Tree and Fan Chart.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TreeCardDensity>(
                        initialValue: selectedTreeDensity,
                        decoration: const InputDecoration(
                          labelText: 'Card density',
                          prefixIcon: Icon(Icons.dashboard_customize_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TreeCardDensity.compact,
                            child: Text('Compact'),
                          ),
                          DropdownMenuItem(
                            value: TreeCardDensity.normal,
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(
                            value: TreeCardDensity.spacious,
                            child: Text('Spacious'),
                          ),
                        ],
                        onChanged: treeDensityAsync.isLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                ref
                                    .read(treeCardDensityProvider.notifier)
                                    .setDensity(value);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: const Text('Hide Years for Living People'),
                  subtitle: const Text(
                    'Show living people without year details in dates and tree cards.',
                  ),
                  value: hideYearsForLiving,
                  onChanged: hideYearsAsync.isLoading
                      ? null
                      : (value) {
                          ref
                              .read(hideYearsForLivingProvider.notifier)
                              .setEnabled(value);
                        },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.calendar_month_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Date Format',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Applied across profile, people list, and tree cards.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<DateDisplayFormat>(
                        initialValue: selectedDateFormat,
                        decoration: const InputDecoration(
                          labelText: 'Display format',
                          prefixIcon: Icon(Icons.date_range_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: DateDisplayFormat.fullDate,
                            child: Text('Full date (DD-MM-YYYY)'),
                          ),
                          DropdownMenuItem(
                            value: DateDisplayFormat.monthYear,
                            child: Text('Month + year'),
                          ),
                          DropdownMenuItem(
                            value: DateDisplayFormat.yearOnly,
                            child: Text('Year only'),
                          ),
                        ],
                        onChanged: dateFormatAsync.isLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                ref
                                    .read(dateDisplayFormatProvider.notifier)
                                    .setFormat(value);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.family_restroom_outlined),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Relationship Labels',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Switch between gendered labels and neutral labels in the tree views.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<RelationshipLabelStyle>(
                        initialValue: selectedLabelStyle,
                        decoration: const InputDecoration(
                          labelText: 'Label style',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: RelationshipLabelStyle.gendered,
                            child: Text('Gendered'),
                          ),
                          DropdownMenuItem(
                            value: RelationshipLabelStyle.neutral,
                            child: Text('Neutral'),
                          ),
                        ],
                        onChanged: labelStyleAsync.isLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                ref
                                    .read(
                                      relationshipLabelStyleProvider.notifier,
                                    )
                                    .setStyle(value);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.pie_chart_outline),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Fan Chart Depth',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Generations shown: $selectedFanDepth',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: selectedFanDepth,
                        decoration: const InputDecoration(
                          labelText: 'Ancestry generations',
                          prefixIcon: Icon(
                            Icons.settings_input_component_outlined,
                          ),
                        ),
                        items: fanChartAncestorGenerationsOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value == 4
                                      ? '4 generations'
                                      : '$value generations',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: fanDepthAsync.isLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                ref
                                    .read(
                                      fanChartAncestorGenerationsProvider
                                          .notifier,
                                    )
                                    .setDepth(value);
                              },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Higher values show more ancestors but can make the fan chart denser.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Privacy',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your family tree data is stored locally on your device. Backups are created only when you choose to export them.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'About',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: Text(appVersion),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  const _AppInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              child: Icon(Icons.account_tree_outlined, size: 34),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VanshVriksh',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Family Tree & Genealogy',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Create, explore, and preserve your family tree with photos, relationships, and life stories.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _importGedcom(BuildContext context, WidgetRef ref) async {
  try {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
      await ref.read(gedcomImportProvider.notifier).importGedcomFile(file, AppConstants.defaultTreeId);
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GEDCOM Import Successful!'))); }
    }
  } catch (e) {
    if (context.mounted) Navigator.of(context).pop();
    if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to import GEDCOM: $e'))); }
  }
}
