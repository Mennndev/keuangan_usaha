import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'daos/business_settings_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/business_settings.dart';
import 'tables/credit_payments.dart';
import 'tables/transactions.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Transactions, BusinessSettings, CreditPayments],
  daos: [TransactionDao, BusinessSettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(transactions, transactions.isCredit);
        await migrator.addColumn(transactions, transactions.creditCustomerName);
        await migrator.addColumn(transactions, transactions.creditDueDate);
        await migrator.addColumn(transactions, transactions.creditPaidAmount);
        await migrator.addColumn(transactions, transactions.creditStatus);
        await migrator.createTable(creditPayments);
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
