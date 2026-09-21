import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLandingView { tree, fan }

enum DateDisplayFormat { fullDate, monthYear, yearOnly }

enum RelationshipLabelStyle { gendered, neutral }

enum TreeCardSpacing { compact, normal, spacious }

enum TreeCardDensity { compact, normal, spacious }

enum PersonPhotoFitMode { cover, contain }

enum TreeLineThickness { thin, normal, thick }

enum TreeConnectorPalette { classic, forest, ocean, sunset }

enum AppThemeMode { system, light, dark }

enum BackupFrequency { daily, weekly, monthly }

const appLandingViewDefault = AppLandingView.tree;
const dateDisplayFormatDefault = DateDisplayFormat.fullDate;
const relationshipLabelStyleDefault = RelationshipLabelStyle.gendered;
const treeCardSpacingDefault = TreeCardSpacing.normal;
const treeCardDensityDefault = TreeCardDensity.normal;
const personPhotoFitModeDefault = PersonPhotoFitMode.cover;
const treeLineThicknessDefault = TreeLineThickness.normal;
const treeConnectorPaletteDefault = TreeConnectorPalette.classic;
const treeSpouseConnectorPaletteDefault = TreeConnectorPalette.classic;
const treeChildConnectorPaletteDefault = TreeConnectorPalette.classic;
const rememberLastRootPersonDefault = true;
const zoomOnLoadDefault = true;
const hideYearsForLivingDefault = false;
const appThemeModeDefault = AppThemeMode.system;
const backupAutoEnabledDefault = false;
const backupFrequencyDefault = BackupFrequency.weekly;
const backupWifiOnlyDefault = true;
const backupEncryptDefault = true;

const _appLandingViewKey = 'app_landing_view';
const _dateDisplayFormatKey = 'date_display_format';
const _relationshipLabelStyleKey = 'relationship_label_style';
const _treeCardSpacingKey = 'tree_card_spacing';
const _treeCardDensityKey = 'tree_card_density';
const _personPhotoFitModeKey = 'person_photo_fit_mode';
const _treeLineThicknessKey = 'tree_line_thickness';
const _treeConnectorPaletteKey = 'tree_connector_palette';
const _treeSpouseConnectorPaletteKey = 'tree_spouse_connector_palette';
const _treeChildConnectorPaletteKey = 'tree_child_connector_palette';
const _treeExpandAllKey = 'genealogy_tree_expand_all';
const _treeExpandedBranchIdsKey = 'genealogy_tree_expanded_branch_ids';
const _zoomOnLoadKey = 'zoom_on_load';
const _rememberLastRootPersonKey = 'remember_last_root_person';
const _lastRootPersonIdKey = 'last_root_person_id';
const _defaultRootPersonIdKey = 'default_root_person_id';
const _hideYearsForLivingKey = 'hide_years_for_living';
const _appThemeModeKey = 'app_theme_mode';
const _backupAutoEnabledKey = 'backup_auto_enabled';
const _backupFrequencyKey = 'backup_frequency';
const _backupWifiOnlyKey = 'backup_wifi_only';
const _backupEncryptKey = 'backup_encrypt';

final appLandingViewProvider =
    AsyncNotifierProvider<AppLandingViewController, AppLandingView>(
      AppLandingViewController.new,
    );

final dateDisplayFormatProvider =
    AsyncNotifierProvider<DateDisplayFormatController, DateDisplayFormat>(
      DateDisplayFormatController.new,
    );

final relationshipLabelStyleProvider =
    AsyncNotifierProvider<
      RelationshipLabelStyleController,
      RelationshipLabelStyle
    >(RelationshipLabelStyleController.new);

final treeCardSpacingProvider =
    AsyncNotifierProvider<TreeCardSpacingController, TreeCardSpacing>(
      TreeCardSpacingController.new,
    );

final treeCardDensityProvider =
    AsyncNotifierProvider<TreeCardDensityController, TreeCardDensity>(
      TreeCardDensityController.new,
    );

final personPhotoFitModeProvider =
    AsyncNotifierProvider<PersonPhotoFitModeController, PersonPhotoFitMode>(
      PersonPhotoFitModeController.new,
    );

final treeLineThicknessProvider =
    AsyncNotifierProvider<TreeLineThicknessController, TreeLineThickness>(
      TreeLineThicknessController.new,
    );

final treeConnectorPaletteProvider =
    AsyncNotifierProvider<TreeConnectorPaletteController, TreeConnectorPalette>(
      TreeConnectorPaletteController.new,
    );

final treeSpouseConnectorPaletteProvider =
    AsyncNotifierProvider<
      TreeSpouseConnectorPaletteController,
      TreeConnectorPalette
    >(TreeSpouseConnectorPaletteController.new);

final treeChildConnectorPaletteProvider =
    AsyncNotifierProvider<
      TreeChildConnectorPaletteController,
      TreeConnectorPalette
    >(TreeChildConnectorPaletteController.new);

final genealogyTreeExpandAllProvider =
    AsyncNotifierProvider<GenealogyTreeExpandAllController, bool>(
      GenealogyTreeExpandAllController.new,
    );

final genealogyTreeExpandedBranchIdsProvider =
    AsyncNotifierProvider<
      GenealogyTreeExpandedBranchIdsController,
      Set<String>
    >(GenealogyTreeExpandedBranchIdsController.new);

final zoomOnLoadProvider = AsyncNotifierProvider<ZoomOnLoadController, bool>(
  ZoomOnLoadController.new,
);

final hideYearsForLivingProvider =
    AsyncNotifierProvider<HideYearsForLivingController, bool>(
      HideYearsForLivingController.new,
    );

final appThemeModeProvider =
    AsyncNotifierProvider<AppThemeModeController, AppThemeMode>(
      AppThemeModeController.new,
    );

final backupAutoEnabledProvider =
    AsyncNotifierProvider<BackupAutoEnabledController, bool>(
      BackupAutoEnabledController.new,
    );

final backupFrequencyProvider =
    AsyncNotifierProvider<BackupFrequencyController, BackupFrequency>(
      BackupFrequencyController.new,
    );

final backupWifiOnlyProvider =
    AsyncNotifierProvider<BackupWifiOnlyController, bool>(
      BackupWifiOnlyController.new,
    );

final backupEncryptProvider =
    AsyncNotifierProvider<BackupEncryptController, bool>(
      BackupEncryptController.new,
    );

final rememberLastRootPersonProvider =
    AsyncNotifierProvider<RememberLastRootPersonController, bool>(
      RememberLastRootPersonController.new,
    );

final lastRootPersonIdProvider =
    AsyncNotifierProvider<LastRootPersonIdController, String?>(
      LastRootPersonIdController.new,
    );

final defaultRootPersonIdProvider =
    AsyncNotifierProvider<DefaultRootPersonIdController, String?>(
      DefaultRootPersonIdController.new,
    );

class AppLandingViewController extends AsyncNotifier<AppLandingView> {
  @override
  Future<AppLandingView> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_appLandingViewKey);
    return switch (stored) {
      'fan' => AppLandingView.fan,
      _ => appLandingViewDefault,
    };
  }

  Future<void> setLandingView(AppLandingView value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _appLandingViewKey,
      value == AppLandingView.fan ? 'fan' : 'tree',
    );
    state = AsyncData(value);
  }
}

class DateDisplayFormatController extends AsyncNotifier<DateDisplayFormat> {
  @override
  Future<DateDisplayFormat> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_dateDisplayFormatKey);
    return switch (stored) {
      'month_year' => DateDisplayFormat.monthYear,
      'year_only' => DateDisplayFormat.yearOnly,
      _ => dateDisplayFormatDefault,
    };
  }

  Future<void> setFormat(DateDisplayFormat value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateDisplayFormatKey, switch (value) {
      DateDisplayFormat.fullDate => 'full_date',
      DateDisplayFormat.monthYear => 'month_year',
      DateDisplayFormat.yearOnly => 'year_only',
    });
    state = AsyncData(value);
  }
}

class RelationshipLabelStyleController
    extends AsyncNotifier<RelationshipLabelStyle> {
  @override
  Future<RelationshipLabelStyle> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_relationshipLabelStyleKey);
    return switch (stored) {
      'neutral' => RelationshipLabelStyle.neutral,
      _ => relationshipLabelStyleDefault,
    };
  }

  Future<void> setStyle(RelationshipLabelStyle value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _relationshipLabelStyleKey,
      value == RelationshipLabelStyle.neutral ? 'neutral' : 'gendered',
    );
    state = AsyncData(value);
  }
}

class TreeCardSpacingController extends AsyncNotifier<TreeCardSpacing> {
  @override
  Future<TreeCardSpacing> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_treeCardSpacingKey);
    return switch (stored) {
      'compact' => TreeCardSpacing.compact,
      'spacious' => TreeCardSpacing.spacious,
      _ => treeCardSpacingDefault,
    };
  }

  Future<void> setSpacing(TreeCardSpacing value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_treeCardSpacingKey, switch (value) {
      TreeCardSpacing.compact => 'compact',
      TreeCardSpacing.normal => 'normal',
      TreeCardSpacing.spacious => 'spacious',
    });
    state = AsyncData(value);
  }
}

class TreeCardDensityController extends AsyncNotifier<TreeCardDensity> {
  @override
  Future<TreeCardDensity> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_treeCardDensityKey);
    return switch (stored) {
      'compact' => TreeCardDensity.compact,
      'spacious' => TreeCardDensity.spacious,
      _ => treeCardDensityDefault,
    };
  }

  Future<void> setDensity(TreeCardDensity value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_treeCardDensityKey, switch (value) {
      TreeCardDensity.compact => 'compact',
      TreeCardDensity.normal => 'normal',
      TreeCardDensity.spacious => 'spacious',
    });
    state = AsyncData(value);
  }
}

class PersonPhotoFitModeController extends AsyncNotifier<PersonPhotoFitMode> {
  @override
  Future<PersonPhotoFitMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_personPhotoFitModeKey);
    return switch (stored) {
      'contain' => PersonPhotoFitMode.contain,
      _ => personPhotoFitModeDefault,
    };
  }

  Future<void> setMode(PersonPhotoFitMode value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _personPhotoFitModeKey,
      value == PersonPhotoFitMode.contain ? 'contain' : 'cover',
    );
    state = AsyncData(value);
  }
}

class TreeLineThicknessController extends AsyncNotifier<TreeLineThickness> {
  @override
  Future<TreeLineThickness> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_treeLineThicknessKey);
    return switch (stored) {
      'thin' => TreeLineThickness.thin,
      'thick' => TreeLineThickness.thick,
      _ => treeLineThicknessDefault,
    };
  }

  Future<void> setThickness(TreeLineThickness value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_treeLineThicknessKey, switch (value) {
      TreeLineThickness.thin => 'thin',
      TreeLineThickness.normal => 'normal',
      TreeLineThickness.thick => 'thick',
    });
    state = AsyncData(value);
  }
}

class TreeConnectorPaletteController
    extends AsyncNotifier<TreeConnectorPalette> {
  @override
  Future<TreeConnectorPalette> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_treeConnectorPaletteKey);
    return switch (stored) {
      'forest' => TreeConnectorPalette.forest,
      'ocean' => TreeConnectorPalette.ocean,
      'sunset' => TreeConnectorPalette.sunset,
      _ => treeConnectorPaletteDefault,
    };
  }

  Future<void> setPalette(TreeConnectorPalette value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_treeConnectorPaletteKey, switch (value) {
      TreeConnectorPalette.classic => 'classic',
      TreeConnectorPalette.forest => 'forest',
      TreeConnectorPalette.ocean => 'ocean',
      TreeConnectorPalette.sunset => 'sunset',
    });
    state = AsyncData(value);
  }
}

class TreeSpouseConnectorPaletteController
    extends AsyncNotifier<TreeConnectorPalette> {
  @override
  Future<TreeConnectorPalette> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_treeSpouseConnectorPaletteKey);
    return switch (stored) {
      'forest' => TreeConnectorPalette.forest,
      'ocean' => TreeConnectorPalette.ocean,
      'sunset' => TreeConnectorPalette.sunset,
      _ => treeSpouseConnectorPaletteDefault,
    };
  }

  Future<void> setPalette(TreeConnectorPalette value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_treeSpouseConnectorPaletteKey, switch (value) {
      TreeConnectorPalette.classic => 'classic',
      TreeConnectorPalette.forest => 'forest',
      TreeConnectorPalette.ocean => 'ocean',
      TreeConnectorPalette.sunset => 'sunset',
    });
    state = AsyncData(value);
  }
}

class TreeChildConnectorPaletteController
    extends AsyncNotifier<TreeConnectorPalette> {
  @override
  Future<TreeConnectorPalette> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_treeChildConnectorPaletteKey);
    return switch (stored) {
      'forest' => TreeConnectorPalette.forest,
      'ocean' => TreeConnectorPalette.ocean,
      'sunset' => TreeConnectorPalette.sunset,
      _ => treeChildConnectorPaletteDefault,
    };
  }

  Future<void> setPalette(TreeConnectorPalette value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_treeChildConnectorPaletteKey, switch (value) {
      TreeConnectorPalette.classic => 'classic',
      TreeConnectorPalette.forest => 'forest',
      TreeConnectorPalette.ocean => 'ocean',
      TreeConnectorPalette.sunset => 'sunset',
    });
    state = AsyncData(value);
  }
}

class GenealogyTreeExpandAllController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_treeExpandAllKey) ?? false;
  }

  Future<void> setExpanded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_treeExpandAllKey, value);
    state = AsyncData(value);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_treeExpandAllKey);
    state = AsyncData(false);
  }
}

class GenealogyTreeExpandedBranchIdsController
    extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_treeExpandedBranchIdsKey)?.toSet() ??
        <String>{};
  }

  Future<void> toggleBranchId(String familyId) async {
    final current = {...state.value ?? <String>{}};
    if (!current.add(familyId)) {
      current.remove(familyId);
    }
    await _save(current);
  }

  Future<void> setExpandedBranchIds(Set<String> ids) async {
    await _save(ids);
  }

  Future<void> clear() async {
    await _save(<String>{});
  }

  Future<void> _save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_treeExpandedBranchIdsKey, ids.toList());
    state = AsyncData(ids);
  }
}

Future<void> resetGenealogyTreeState(WidgetRef ref) async {
  await ref.read(genealogyTreeExpandedBranchIdsProvider.notifier).clear();
}

class ZoomOnLoadController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_zoomOnLoadKey) ?? zoomOnLoadDefault;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_zoomOnLoadKey, value);
    state = AsyncData(value);
  }
}

class HideYearsForLivingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideYearsForLivingKey) ?? hideYearsForLivingDefault;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideYearsForLivingKey, value);
    state = AsyncData(value);
  }
}

class AppThemeModeController extends AsyncNotifier<AppThemeMode> {
  @override
  Future<AppThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_appThemeModeKey);
    return switch (stored) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => appThemeModeDefault,
    };
  }

  Future<void> setMode(AppThemeMode value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appThemeModeKey, switch (value) {
      AppThemeMode.system => 'system',
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
    });
    state = AsyncData(value);
  }
}

class BackupAutoEnabledController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backupAutoEnabledKey) ?? backupAutoEnabledDefault;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupAutoEnabledKey, value);
    state = AsyncData(value);
  }
}

class BackupFrequencyController extends AsyncNotifier<BackupFrequency> {
  @override
  Future<BackupFrequency> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_backupFrequencyKey);
    return switch (stored) {
      'daily' => BackupFrequency.daily,
      'monthly' => BackupFrequency.monthly,
      _ => backupFrequencyDefault,
    };
  }

  Future<void> setFrequency(BackupFrequency value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupFrequencyKey, switch (value) {
      BackupFrequency.daily => 'daily',
      BackupFrequency.weekly => 'weekly',
      BackupFrequency.monthly => 'monthly',
    });
    state = AsyncData(value);
  }
}

class BackupWifiOnlyController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backupWifiOnlyKey) ?? backupWifiOnlyDefault;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupWifiOnlyKey, value);
    state = AsyncData(value);
  }
}

class BackupEncryptController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backupEncryptKey) ?? backupEncryptDefault;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupEncryptKey, value);
    state = AsyncData(value);
  }
}

class RememberLastRootPersonController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberLastRootPersonKey) ??
        rememberLastRootPersonDefault;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberLastRootPersonKey, value);
    if (!value) {
      await prefs.remove(_lastRootPersonIdKey);
    }
    state = AsyncData(value);
  }
}

class LastRootPersonIdController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastRootPersonIdKey);
  }

  Future<void> setPersonId(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.trim().isEmpty) {
      await prefs.remove(_lastRootPersonIdKey);
    } else {
      await prefs.setString(_lastRootPersonIdKey, value);
    }
    state = AsyncData(value);
  }
}

class DefaultRootPersonIdController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultRootPersonIdKey);
  }

  Future<void> setPersonId(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.trim().isEmpty) {
      await prefs.remove(_defaultRootPersonIdKey);
    } else {
      await prefs.setString(_defaultRootPersonIdKey, value);
    }
    state = AsyncData(value);
  }
}
