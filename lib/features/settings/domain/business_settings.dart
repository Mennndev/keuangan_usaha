import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

enum AppThemePreference { system, light, dark }

extension AppThemePreferenceX on AppThemePreference {
  String get databaseValue => name;

  String get label => switch (this) {
    AppThemePreference.system => 'Sistem',
    AppThemePreference.light => 'Terang',
    AppThemePreference.dark => 'Gelap',
  };

  IconData get icon => switch (this) {
    AppThemePreference.system => Icons.brightness_auto_outlined,
    AppThemePreference.light => Icons.light_mode_outlined,
    AppThemePreference.dark => Icons.dark_mode_outlined,
  };

  ThemeMode get themeMode => switch (this) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  static AppThemePreference fromDatabase(String value) {
    return AppThemePreference.values.firstWhere(
      (mode) => mode.databaseValue == value,
      orElse: () => AppThemePreference.system,
    );
  }
}

class BusinessProfile {
  const BusinessProfile({
    required this.businessName,
    required this.theme,
    this.ownerName,
    this.currencyCode = AppConstants.currencyCode,
  });

  final String businessName;
  final String? ownerName;
  final String currencyCode;
  final AppThemePreference theme;
}
