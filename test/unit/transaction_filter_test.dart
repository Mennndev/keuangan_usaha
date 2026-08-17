import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/features/transactions/domain/finance_transaction.dart';
import 'package:keuangan_usaha/features/transactions/domain/transaction_filter.dart';

void main() {
  final fixtures = [
    FinanceTransaction(
      id: '1',
      type: TransactionType.income,
      name: 'Penjualan toko',
      amount: 1200000,
      category: 'Penjualan',
      notes: 'Tunai',
      transactionDate: DateTime(2026, 7, 17),
      createdAt: DateTime(2026, 7, 17),
      updatedAt: DateTime(2026, 7, 17),
    ),
    FinanceTransaction(
      id: '2',
      type: TransactionType.expense,
      name: 'Belanja stok',
      amount: 700000,
      category: 'Stok',
      notes: 'Pemasok utama',
      transactionDate: DateTime(2026, 7, 16),
      createdAt: DateTime(2026, 7, 16),
      updatedAt: DateTime(2026, 7, 16),
    ),
    FinanceTransaction(
      id: '3',
      type: TransactionType.income,
      name: 'Jasa desain',
      amount: 2000000,
      transactionDate: DateTime(2026, 6, 30),
      createdAt: DateTime(2026, 6, 30),
      updatedAt: DateTime(2026, 6, 30),
    ),
  ];

  test('mencari berdasarkan nama, kategori, dan keterangan', () {
    expect(
      filterAndSortTransactions(
        fixtures,
        const TransactionFilter(search: 'pemasok'),
      ).single.id,
      '2',
    );
    expect(
      filterAndSortTransactions(
        fixtures,
        const TransactionFilter(search: 'penjualan'),
      ).single.id,
      '1',
    );
  });

  test('memfilter jenis dan rentang tanggal', () {
    final result = filterAndSortTransactions(
      fixtures,
      TransactionFilter(
        type: TransactionType.income,
        start: DateTime(2026, 7),
        end: DateTime(2026, 8),
      ),
    );
    expect(result.map((item) => item.id), ['1']);
  });

  test('mengurutkan nominal terbesar dan terkecil', () {
    final descending = filterAndSortTransactions(
      fixtures,
      const TransactionFilter(sort: TransactionSort.highestAmount),
    );
    final ascending = filterAndSortTransactions(
      fixtures,
      const TransactionFilter(sort: TransactionSort.lowestAmount),
    );
    expect(descending.map((item) => item.amount), [2000000, 1200000, 700000]);
    expect(ascending.map((item) => item.amount), [700000, 1200000, 2000000]);
  });
}
