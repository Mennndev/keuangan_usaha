import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/transactions.dart';

part 'transaction_dao.g.dart';

enum TransactionSqlSort { newest, oldest, highestAmount, lowestAmount }

class FinanceTotalsRecord {
  const FinanceTotalsRecord({required this.income, required this.expense});

  final int income;
  final int expense;
}

class CashFlowRecord {
  const CashFlowRecord({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final int income;
  final int expense;
}

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.attachedDatabase);

  Future<void> insertTransaction(TransactionsCompanion transaction) async {
    await into(transactions).insert(transaction);
  }

  Future<bool> updateTransaction(
    String id,
    TransactionsCompanion transaction,
  ) async {
    final count = await (update(
      transactions,
    )..where((table) => table.id.equals(id))).write(transaction);
    return count == 1;
  }

  Future<bool> deleteTransaction(String id) async {
    final count = await (delete(
      transactions,
    )..where((table) => table.id.equals(id))).go();
    return count == 1;
  }

  Future<int> deleteAllTransactions() => delete(transactions).go();

  Future<TransactionRecord?> findById(String id) {
    return (select(
      transactions,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Stream<TransactionRecord?> watchById(String id) {
    return (select(
      transactions,
    )..where((table) => table.id.equals(id))).watchSingleOrNull();
  }

  Future<List<TransactionRecord>> getAllTransactions() {
    final query = select(transactions)
      ..orderBy([
        (table) => OrderingTerm.desc(table.transactionDate),
        (table) => OrderingTerm.desc(table.createdAt),
      ]);
    return query.get();
  }

  Stream<List<TransactionRecord>> watchFiltered({
    String? search,
    String? type,
    DateTime? start,
    DateTime? end,
    TransactionSqlSort sort = TransactionSqlSort.newest,
    int limit = 30,
    int offset = 0,
  }) {
    final query = select(transactions);
    final trimmedSearch = search?.trim();

    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      query.where(
        (table) =>
            table.name.contains(trimmedSearch) |
            table.category.contains(trimmedSearch) |
            table.notes.contains(trimmedSearch),
      );
    }
    if (type != null) {
      query.where((table) => table.type.equals(type));
    }
    if (start != null) {
      query.where((table) => table.transactionDate.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where((table) => table.transactionDate.isSmallerThanValue(end));
    }

    switch (sort) {
      case TransactionSqlSort.newest:
        query.orderBy([
          (table) => OrderingTerm.desc(table.transactionDate),
          (table) => OrderingTerm.desc(table.createdAt),
        ]);
        break;
      case TransactionSqlSort.oldest:
        query.orderBy([
          (table) => OrderingTerm.asc(table.transactionDate),
          (table) => OrderingTerm.asc(table.createdAt),
        ]);
        break;
      case TransactionSqlSort.highestAmount:
        query.orderBy([
          (table) => OrderingTerm.desc(table.amount),
          (table) => OrderingTerm.desc(table.transactionDate),
        ]);
        break;
      case TransactionSqlSort.lowestAmount:
        query.orderBy([
          (table) => OrderingTerm.asc(table.amount),
          (table) => OrderingTerm.desc(table.transactionDate),
        ]);
        break;
    }
    query.limit(limit, offset: offset);
    return query.watch();
  }

  Stream<FinanceTotalsRecord> watchTotals({
    required DateTime start,
    required DateTime end,
  }) {
    return customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expense
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {transactions},
    ).watchSingle().map(
      (row) => FinanceTotalsRecord(
        income: row.read<int>('income'),
        expense: row.read<int>('expense'),
      ),
    );
  }

  Stream<List<CashFlowRecord>> watchCashFlow({
    required DateTime start,
    required DateTime end,
    required bool groupByMonth,
  }) {
    final labelExpression = groupByMonth
        ? "strftime('%Y-%m', transaction_date, 'unixepoch', 'localtime')"
        : "strftime('%Y-%m-%d', transaction_date, 'unixepoch', 'localtime')";
    return customSelect(
      '''
      SELECT
        $labelExpression AS label,
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expense
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      GROUP BY label
      ORDER BY label ASC
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {transactions},
    ).watch().map(
      (rows) => rows
          .map(
            (row) => CashFlowRecord(
              label: row.read<String>('label'),
              income: row.read<int>('income'),
              expense: row.read<int>('expense'),
            ),
          )
          .toList(growable: false),
    );
  }
}
