import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/database/app_database.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('keuangan_migration');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  File databaseFile() => File(p.join(tempDir.path, 'keuangan_usaha.sqlite'));

  TransactionsCompanion creditTransaction({String id = 'trx-1'}) {
    final timestamp = DateTime(2026, 7, 1, 9);
    return TransactionsCompanion.insert(
      id: id,
      type: 'income',
      name: 'Penjualan kredit $id',
      amount: 150000,
      transactionDate: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
      isCredit: const Value(true),
      creditCustomerName: const Value('Budi Santoso'),
      creditStatus: const Value('pending'),
    );
  }

  /// Menyiapkan berkas database pada skema v2: hanya tabel Drift inti yang
  /// tersisa, tabel raw SQL dari v3-v5 dihapus dan user_version diturunkan.
  Future<void> downgradeToV2(AppDatabase database) async {
    await database.customStatement('DROP TABLE IF EXISTS product_sale_items');
    await database.customStatement(
      'DROP TABLE IF EXISTS inventory_stock_movements',
    );
    await database.customStatement('DROP TABLE IF EXISTS inventory_products');
    await database.customStatement('DROP TABLE IF EXISTS customers');
    await database.customStatement('PRAGMA user_version = 2');
  }

  Future<List<String>> tableNames(AppDatabase database) async {
    final rows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        )
        .get();
    return rows.map((row) => row.read<String>('name')).toList(growable: false);
  }

  Future<int> userVersion(AppDatabase database) async {
    final row = await database.customSelect('PRAGMA user_version').getSingle();
    return row.read<int>('user_version');
  }

  test('migrasi v2 -> v5 mempertahankan transaksi lama', () async {
    final before = AppDatabase.forTesting(NativeDatabase(databaseFile()));
    await before.transactionDao.insertTransaction(creditTransaction());
    await before.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        id: 'trx-2',
        type: 'expense',
        name: 'Belanja stok',
        amount: 75000,
        transactionDate: DateTime(2026, 7, 2),
        createdAt: DateTime(2026, 7, 2),
        updatedAt: DateTime(2026, 7, 2),
        creditStatus: const Value('pending'),
      ),
    );
    await downgradeToV2(before);
    await before.close();

    final migrated = AppDatabase.forTesting(NativeDatabase(databaseFile()));
    addTearDown(migrated.close);

    final credit = await migrated.transactionDao.findById('trx-1');
    expect(credit, isNotNull);
    expect(credit!.amount, 150000);
    expect(credit.isCredit, isTrue);
    expect(credit.creditCustomerName, 'Budi Santoso');
    expect(credit.creditStatus, 'pending');

    final expense = await migrated.transactionDao.findById('trx-2');
    expect(expense?.amount, 75000);
    expect(expense?.type, 'expense');
    expect(await migrated.transactionDao.getAllTransactions(), hasLength(2));

    final tables = await tableNames(migrated);
    expect(
      tables,
      containsAll(<String>[
        'inventory_products',
        'inventory_stock_movements',
        'product_sale_items',
        'customers',
      ]),
    );
    expect(await userVersion(migrated), 5);
  });

  test('migrasi mengisi pelanggan dari nama pelanggan kredit lama', () async {
    final before = AppDatabase.forTesting(NativeDatabase(databaseFile()));
    await before.transactionDao.insertTransaction(creditTransaction());
    await downgradeToV2(before);
    await before.close();

    final migrated = AppDatabase.forTesting(NativeDatabase(databaseFile()));
    addTearDown(migrated.close);

    final customers = await migrated
        .customSelect('SELECT name FROM customers')
        .get();
    expect(
      customers.map((row) => row.read<String>('name')),
      contains('Budi Santoso'),
    );
  });

  test('tabel product_sales lama dimigrasikan utuh lalu dihapus', () async {
    final before = AppDatabase.forTesting(NativeDatabase(databaseFile()));
    await before.transactionDao.insertTransaction(creditTransaction());
    await downgradeToV2(before);
    await before.customStatement('''CREATE TABLE product_sales (
      transaction_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      product_name_snapshot TEXT NOT NULL,
      brand_snapshot TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      unit_price INTEGER NOT NULL
    )''');
    // Satu transaksi dengan dua baris produk: keduanya harus selamat.
    await before.customStatement('''
      INSERT INTO product_sales VALUES
        ('trx-1', 'prod-a', 'Produk A', 'Vanestrix', 2, 25000),
        ('trx-1', 'prod-b', 'Produk B', 'Dioses', 1, 40000)
    ''');
    await before.close();

    final migrated = AppDatabase.forTesting(NativeDatabase(databaseFile()));
    addTearDown(migrated.close);

    final sales = await migrated.productDao.salesForTransaction('trx-1');
    expect(sales, hasLength(2));
    expect(
      sales.map((sale) => sale.productId),
      containsAll(<String>['prod-a', 'prod-b']),
    );
    expect(sales.map((sale) => sale.quantity), containsAll(<int>[2, 1]));
    expect(await tableNames(migrated), isNot(contains('product_sales')));
  });

  test('membuka ulang database v5 tidak menggandakan data', () async {
    final first = AppDatabase.forTesting(NativeDatabase(databaseFile()));
    await first.transactionDao.insertTransaction(creditTransaction());
    await first.customStatement('''
      INSERT INTO product_sale_items
        (id, transaction_id, product_id, product_name_snapshot, brand_snapshot, quantity, unit_price)
      VALUES ('sale-1', 'trx-1', 'prod-a', 'Produk A', 'Vanestrix', 2, 25000)
    ''');
    await first.close();

    final second = AppDatabase.forTesting(NativeDatabase(databaseFile()));
    await second.customStatement('PRAGMA user_version = 5');
    await second
        .customSelect('SELECT COUNT(*) AS total FROM product_sale_items')
        .getSingle()
        .then((row) => expect(row.read<int>('total'), 1));
    await second.close();

    final third = AppDatabase.forTesting(NativeDatabase(databaseFile()));
    addTearDown(third.close);

    expect(await userVersion(third), 5);
    expect(await third.transactionDao.getAllTransactions(), hasLength(1));
    expect(await third.productDao.salesForTransaction('trx-1'), hasLength(1));
    expect(
      (await third.customSelect('SELECT name FROM customers').get()),
      hasLength(1),
    );
  });
}
