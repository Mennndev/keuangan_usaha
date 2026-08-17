import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertFixture({
    String id = 'fixture',
    String type = 'income',
    int amount = 100000,
    DateTime? date,
  }) {
    final timestamp = DateTime(2026, 7, 17, 10);
    return database.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        id: id,
        type: type,
        name: 'Transaksi $id',
        amount: amount,
        transactionDate: date ?? timestamp,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  test('insert transaksi', () async {
    await insertFixture();
    final record = await database.transactionDao.findById('fixture');
    expect(record?.amount, 100000);
  });

  test('update transaksi', () async {
    await insertFixture();
    final updated = await database.transactionDao.updateTransaction(
      'fixture',
      const TransactionsCompanion(amount: Value(250000)),
    );
    expect(updated, isTrue);
    expect((await database.transactionDao.findById('fixture'))?.amount, 250000);
  });

  test('delete transaksi', () async {
    await insertFixture();
    expect(await database.transactionDao.deleteTransaction('fixture'), isTrue);
    expect(await database.transactionDao.findById('fixture'), isNull);
  });

  test('query berdasarkan jenis', () async {
    await insertFixture(id: 'income', type: 'income');
    await insertFixture(id: 'expense', type: 'expense');
    final records = await database.transactionDao
        .watchFiltered(type: 'expense', limit: 30)
        .first;
    expect(records.map((record) => record.id), ['expense']);
  });

  test('query berdasarkan periode', () async {
    await insertFixture(id: 'june', date: DateTime(2026, 6, 30));
    await insertFixture(id: 'july', date: DateTime(2026, 7, 10));
    final records = await database.transactionDao
        .watchFiltered(
          start: DateTime(2026, 7),
          end: DateTime(2026, 8),
          limit: 30,
        )
        .first;
    expect(records.map((record) => record.id), ['july']);
  });

  test('aggregation laporan menghitung pemasukan dan pengeluaran', () async {
    await insertFixture(id: 'income', type: 'income', amount: 900000);
    await insertFixture(id: 'expense', type: 'expense', amount: 350000);
    final totals = await database.transactionDao
        .watchTotals(start: DateTime(2026, 7), end: DateTime(2026, 8))
        .first;
    expect(totals.income, 900000);
    expect(totals.expense, 350000);
  });

  test('aggregation grafik mengelompokkan data nyata', () async {
    await insertFixture(id: 'income', type: 'income', amount: 900000);
    final points = await database.transactionDao
        .watchCashFlow(
          start: DateTime(2026, 7),
          end: DateTime(2026, 8),
          groupByMonth: false,
        )
        .first;
    expect(points, hasLength(1));
    expect(points.single.income, 900000);
  });

  test('database baru benar-benar kosong', () async {
    expect(await database.transactionDao.getAllTransactions(), isEmpty);
    expect(await database.businessSettingsDao.getSettings(), isNull);
  });
}
