import 'package:drift/drift.dart' hide isNotNull;
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

  Future<void> insertFixture() {
    final timestamp = DateTime(2026, 7, 17, 10);
    return database.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        id: 'fixture',
        type: 'income',
        name: 'Penjualan awal',
        amount: 100000,
        transactionDate: timestamp,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  test('updateTransaction memperbarui seluruh kolom transaksi', () async {
    await insertFixture();
    final updatedAt = DateTime(2026, 7, 20, 14, 30);

    final updated = await database.transactionDao.updateTransaction(
      'fixture',
      TransactionsCompanion(
        type: const Value('expense'),
        name: const Value('Pembelian stok'),
        amount: const Value(250000),
        category: const Value('Operasional'),
        notes: const Value('Diperbarui dari pengujian'),
        transactionDate: Value(DateTime(2026, 7, 19)),
        updatedAt: Value(updatedAt),
      ),
    );

    expect(updated, isTrue);
    final record = await database.transactionDao.findById('fixture');
    expect(record, isNotNull);
    expect(record!.type, 'expense');
    expect(record.name, 'Pembelian stok');
    expect(record.amount, 250000);
    expect(record.category, 'Operasional');
    expect(record.notes, 'Diperbarui dari pengujian');
    expect(record.transactionDate, DateTime(2026, 7, 19));
    expect(record.updatedAt, updatedAt);
  });

  test(
    'updateTransaction mengembalikan false untuk id yang tidak ada',
    () async {
      final updated = await database.transactionDao.updateTransaction(
        'missing',
        const TransactionsCompanion(amount: Value(1000)),
      );

      expect(updated, isFalse);
    },
  );
}
