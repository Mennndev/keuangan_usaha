import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/features/transactions/domain/finance_summary.dart';
import 'package:keuangan_usaha/features/transactions/domain/finance_transaction.dart';

void main() {
  final transactions = [
    FinanceTransaction(
      id: 'income-1',
      type: TransactionType.income,
      name: 'Penjualan',
      amount: 2500000,
      transactionDate: DateTime(2026, 7, 17),
      createdAt: DateTime(2026, 7, 17),
      updatedAt: DateTime(2026, 7, 17),
    ),
    FinanceTransaction(
      id: 'income-2',
      type: TransactionType.income,
      name: 'Jasa',
      amount: 500000,
      transactionDate: DateTime(2026, 7, 17),
      createdAt: DateTime(2026, 7, 17),
      updatedAt: DateTime(2026, 7, 17),
    ),
    FinanceTransaction(
      id: 'expense-1',
      type: TransactionType.expense,
      name: 'Stok',
      amount: 750000,
      transactionDate: DateTime(2026, 7, 17),
      createdAt: DateTime(2026, 7, 17),
      updatedAt: DateTime(2026, 7, 17),
    ),
  ];

  test('menghitung total pemasukan', () {
    final summary = FinanceSummary.fromTransactions(transactions);
    expect(summary.income, 3000000);
  });

  test('menghitung total pengeluaran', () {
    final summary = FinanceSummary.fromTransactions(transactions);
    expect(summary.expense, 750000);
  });

  test('menghitung saldo dari pemasukan dikurangi pengeluaran', () {
    final summary = FinanceSummary.fromTransactions(transactions);
    expect(summary.balance, 2250000);
  });
}
