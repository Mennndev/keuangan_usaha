import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'daos/business_settings_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/business_settings.dart';
import 'tables/transactions.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Transactions, BusinessSettings],
  daos: [TransactionDao, BusinessSettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      // Schema v1 is the baseline. Future migrations are added here in order.
      if (from < 1) {
        await migrator.createAll();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> deleteAllData() async {
    await transaction(() async {
      await transactionDao.deleteAllTransactions();
      await businessSettingsDao.deleteAllSettings();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documents = await getApplicationDocumentsDirectory();
    final temporary = await getTemporaryDirectory();
    sqlite3.tempDirectory = temporary.path;
    final file = File(path.join(documents.path, 'keuangan_usaha.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
