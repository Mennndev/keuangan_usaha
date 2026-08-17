import 'package:drift/drift.dart';

import '../../../core/constants/app_constants.dart';
import '../../../database/app_database.dart';
import '../domain/business_settings.dart';

class SettingsRepository {
  SettingsRepository(this._database);

  final AppDatabase _database;

  Stream<BusinessProfile?> watchProfile() {
    return _database.businessSettingsDao.watchSettings().map((record) {
      if (record == null) return null;
      return BusinessProfile(
        businessName: record.businessName,
        ownerName: record.ownerName,
        currencyCode: record.currencyCode,
        theme: AppThemePreferenceX.fromDatabase(record.themeMode),
      );
    });
  }

  Future<void> saveProfile(BusinessProfile profile) async {
    final existing = await _database.businessSettingsDao.getSettings();
    final now = DateTime.now();
    await _database.businessSettingsDao.saveSettings(
      BusinessSettingsCompanion(
        id: const Value(AppConstants.databaseSettingsId),
        businessName: Value(
          profile.businessName.trim().isEmpty
              ? AppConstants.appName
              : profile.businessName.trim(),
        ),
        ownerName: Value(_optionalText(profile.ownerName)),
        currencyCode: Value(profile.currencyCode),
        themeMode: Value(profile.theme.databaseValue),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> deleteAllData() => _database.deleteAllData();
}

String? _optionalText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
