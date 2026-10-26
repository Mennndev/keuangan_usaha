import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/database/app_database.dart';
import 'package:keuangan_usaha/database/database_provider.dart';
import 'package:keuangan_usaha/features/transactions/domain/finance_summary.dart';
import 'package:keuangan_usaha/features/transactions/domain/finance_transaction.dart';
import 'package:keuangan_usaha/features/transactions/domain/transaction_filter.dart';
import 'package:keuangan_usaha/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
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
        category: const Value('Penjualan'),
        transactionDate: timestamp,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  test('updateTransaction memperbarui daftar dan ringkasan kas', () async {
    await insertFixture();
    const filter = TransactionFilter();
    final range = PeriodRange(start: DateTime(2026, 7), end: DateTime(2026, 8));
    final subscriptions = [
      container.listen(transactionsProvider(filter), (_, _) {}),
      container.listen(financeTotalsProvider(range), (_, _) {}),
      container.listen(creditsProvider, (_, _) {}),
    ];
    addTearDown(() {
      for (final subscription in subscriptions) {
        subscription.close();
      }
    });

    final before = await container.read(transactionsProvider(filter).future);
    expect(before.single.type, TransactionType.income);
    final beforeTotals = await container.read(
      financeTotalsProvider(range).future,
    );
    expect(beforeTotals.income, 100000);
    expect(beforeTotals.expense, 0);

    await container
        .read(transactionControllerProvider.notifier)
        .updateTransaction(
          'fixture',
          TransactionInput(
            type: TransactionType.expense,
            name: 'Pembelian stok',
            amount: 40000,
            transactionDate: DateTime(2026, 7, 19),
            category: 'Operasional',
            notes: 'Setelah diperbarui',
          ),
        );
    await container.pump();

    final after = await container.read(transactionsProvider(filter).future);
    expect(after, hasLength(1));
    expect(after.single.type, TransactionType.expense);
    expect(after.single.name, 'Pembelian stok');
    expect(after.single.amount, 40000);
    expect(after.single.category, 'Operasional');
    expect(after.single.notes, 'Setelah diperbarui');
    expect(after.single.transactionDate, DateTime(2026, 7, 19));

    final afterTotals = await container.read(
      financeTotalsProvider(range).future,
    );
    expect(afterTotals.income, 0);
    expect(afterTotals.expense, 40000);
    expect(
      container.read(transactionControllerProvider),
      isA<AsyncData<void>>(),
    );
  });

  test(
    'updateTransaction pada id yang tidak ada melempar StateError',
    () async {
      final controller = container.read(transactionControllerProvider.notifier);

      await expectLater(
        controller.updateTransaction(
          'missing',
          TransactionInput(
            type: TransactionType.income,
            name: 'Tidak ada',
            amount: 1000,
            transactionDate: DateTime(2026, 7, 19),
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        container.read(transactionControllerProvider),
        isA<AsyncError<void>>(),
      );
    },
  );
}
