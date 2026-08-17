import 'package:drift/drift.dart';

@DataClassName('BusinessSettingRecord')
class BusinessSettings extends Table {
  TextColumn get id => text()();

  TextColumn get businessName => text()();

  TextColumn get ownerName => text().nullable()();

  TextColumn get currencyCode => text().withDefault(const Constant('IDR'))();

  TextColumn get themeMode => text().customConstraint(
    "NOT NULL CHECK (theme_mode IN ('system', 'light', 'dark'))",
  )();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
