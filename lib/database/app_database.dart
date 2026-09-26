import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'daos/business_settings_dao.dart';
import 'daos/product_dao.dart';
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

  late final productDao = ProductDao(this);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createInventoryTables();
      await ensureProductSaleItems();
      await ensureCustomersTable();
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
      if (from < 3) {
        await _createInventoryTables();
      }
      if (from < 4) {
        await ensureProductSaleItems();
      }
      if (from < 5) {
        await ensureCustomersTable();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await ensureProductSaleItems();
      await ensureCustomersTable();
    },
  );

  Future<void> deleteAllData() async {
    await ensureCustomersTable();
    await transaction(() async {
      await transactionDao.deleteAllTransactions();
      await customStatement('DELETE FROM product_sale_items');
      await customStatement('DELETE FROM inventory_stock_movements');
      await customStatement('DELETE FROM inventory_products');
      await customStatement('DELETE FROM customers');
      await businessSettingsDao.deleteAllSettings();
    });
  }

  Future<void> _createInventoryTables() async {
    await customStatement('''CREATE TABLE IF NOT EXISTS inventory_products (
      id TEXT PRIMARY KEY NOT NULL,
      brand TEXT NOT NULL CHECK (brand IN ('Vanestrix', 'Dioses', 'Vinbee', 'Zahwa')),
      name TEXT NOT NULL,
      selling_price INTEGER NOT NULL CHECK (selling_price > 0),
      stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
      archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''');
    await customStatement(
      '''CREATE TABLE IF NOT EXISTS inventory_stock_movements (
      id TEXT PRIMARY KEY NOT NULL,
      product_id TEXT,
      product_name_snapshot TEXT NOT NULL,
      brand_snapshot TEXT NOT NULL,
      quantity_change INTEGER NOT NULL,
      reason TEXT NOT NULL CHECK (reason IN ('restock', 'sale', 'adjustment')),
      movement_date TEXT NOT NULL,
      notes TEXT,
      transaction_id TEXT,
      created_at TEXT NOT NULL
    )''',
    );
  }

  Future<void> ensureProductSaleItems() async {
    await customStatement('''CREATE TABLE IF NOT EXISTS product_sale_items (
      id TEXT PRIMARY KEY NOT NULL,
      transaction_id TEXT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
      product_id TEXT NOT NULL,
      product_name_snapshot TEXT NOT NULL,
      brand_snapshot TEXT NOT NULL,
      quantity INTEGER NOT NULL CHECK (quantity > 0),
      unit_price INTEGER NOT NULL CHECK (unit_price > 0)
    )''');
    await customStatement(
      '''CREATE INDEX IF NOT EXISTS product_sale_items_transaction_idx
      ON product_sale_items (transaction_id)''',
    );
    final legacyTable = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'product_sales'",
    ).getSingleOrNull();
    if (legacyTable != null) {
      await customStatement('''INSERT OR IGNORE INTO product_sale_items
        (id, transaction_id, product_id, product_name_snapshot, brand_snapshot, quantity, unit_price)
        SELECT old.transaction_id, old.transaction_id, old.product_id, old.product_name_snapshot,
          old.brand_snapshot, old.quantity, old.unit_price
        FROM product_sales old
        WHERE NOT EXISTS (
          SELECT 1 FROM product_sale_items current
          WHERE current.transaction_id = old.transaction_id
        )''');
      await customStatement('DROP TABLE product_sales');
    }
  }

  Future<void> ensureCustomersTable() async {
    await customStatement('''CREATE TABLE IF NOT EXISTS customers (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL COLLATE NOCASE UNIQUE,
      phone TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''');
    await customStatement('''INSERT OR IGNORE INTO customers
      (id, name, phone, notes, created_at, updated_at)
      SELECT lower(hex(randomblob(16))), trim(credit_customer_name), NULL, NULL,
        strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
      FROM transactions
      WHERE credit_customer_name IS NOT NULL AND trim(credit_customer_name) <> ''
    ''');
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
