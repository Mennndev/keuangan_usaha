import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/business_settings.dart';

part 'business_settings_dao.g.dart';

@DriftAccessor(tables: [BusinessSettings])
class BusinessSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$BusinessSettingsDaoMixin {
  BusinessSettingsDao(super.attachedDatabase);

  Stream<BusinessSettingRecord?> watchSettings() {
    return (select(businessSettings)..limit(1)).watchSingleOrNull();
  }

  Future<BusinessSettingRecord?> getSettings() {
    return (select(businessSettings)..limit(1)).getSingleOrNull();
  }

  Future<void> saveSettings(BusinessSettingsCompanion settings) {
    return into(businessSettings).insertOnConflictUpdate(settings);
  }

  Future<int> deleteAllSettings() => delete(businessSettings).go();
}
