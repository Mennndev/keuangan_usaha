import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/app_database.dart';
import '../../../database/daos/transaction_dao.dart';
import '../domain/finance_summary.dart';
import '../domain/finance_transaction.dart';
import '../domain/transaction_filter.dart';

class TransactionRepository {
  TransactionRepository(this._dao, {this._uuid = const Uuid()});

  final TransactionDao _dao;
  final Uuid _uuid;

  Future<String> create(TransactionInput input) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _dao.insertTransaction(
      TransactionsCompanion.insert(
        id: id,
        type: input.type.databaseValue,
        name: input.name.trim(),
        amount: input.amount,
        category: Value(_optionalText(input.category)),
        notes: Value(_optionalText(input.notes)),
        transactionDate: input.transactionDate,
        createdAt: now,
        updatedAt: now,
        isCredit: Value(input.isCredit),
        creditCustomerName: Value(_optionalText(input.creditCustomerName)),
        creditDueDate: Value(input.creditDueDate),
        creditPaidAmount: const Value(0),
        creditStatus: const Value('pending'),
      ),
    );
    return id;
  }

  Future<bool> update(String id, TransactionInput input) {
    return _dao.updateTransaction(
      id,
      TransactionsCompanion(
        type: Value(input.type.databaseValue),
        name: Value(input.name.trim()),
        amount: Value(input.amount),
        category: Value(_optionalText(input.category)),
        notes: Value(_optionalText(input.notes)),
        transactionDate: Value(input.transactionDate),
        updatedAt: Value(DateTime.now()),
        isCredit: Value(input.isCredit),
        creditCustomerName: Value(_optionalText(input.creditCustomerName)),
        creditDueDate: Value(input.creditDueDate),
      ),
    );
  }

  Future<bool> delete(String id) => _dao.deleteTransaction(id);

  Future<FinanceTransaction?> findById(String id) async {
    final record = await _dao.findById(id);
    return record == null ? null : _map(record);
  }

  Stream<FinanceTransaction?> watchById(String id) {
    return _dao
        .watchById(id)
        .map((record) => record == null ? null : _map(record));
  }

  Stream<List<FinanceTransaction>> watchFiltered(TransactionFilter filter) {
    return _dao
        .watchFiltered(
          search: filter.search,
          type: filter.type?.databaseValue,
          start: filter.start,
          end: filter.end,
          sort: _mapSort(filter.sort),
          limit: filter.limit,
          offset: filter.offset,
        )
        .map((records) => records.map(_map).toList(growable: false));
  }

  Stream<List<FinanceTransaction>> watchLatest({int limit = 5}) {
    return watchFiltered(TransactionFilter(limit: limit));
  }

  Stream<FinanceSummary> watchTotals(PeriodRange range) {
    return _dao
        .watchTotals(start: range.start, end: range.end)
        .map(
          (record) =>
              FinanceSummary(income: record.income, expense: record.expense),
        );
  }

  Stream<List<CashFlowPoint>> watchCashFlow(CashFlowRequest request) {
    return _dao
        .watchCashFlow(
          start: request.range.start,
          end: request.range.end,
          groupByMonth: request.groupByMonth,
        )
        .map(
          (records) => records
              .map(
                (record) => CashFlowPoint(
                  label: record.label,
                  income: record.income,
                  expense: record.expense,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<List<FinanceTransaction>> getAll() async {
    final records = await _dao.getAllTransactions();
    return records.map(_map).toList(growable: false);
  }

  Future<List<FinanceTransaction>> getCredits({bool includePaid = false}) async {
    final records = await _dao.getAllTransactions();
    return records
        .where((r) => r.isCredit)
        .where((r) => includePaid || r.creditStatus != 'paid')
        .map(_map)
        .toList(growable: false);
  }

  FinanceTransaction _map(TransactionRecord record) {
    return FinanceTransaction(
      id: record.id,
      type: TransactionTypeX.fromDatabase(record.type),
      name: record.name,
      amount: record.amount,
      category: record.category,
      notes: record.notes,
      transactionDate: record.transactionDate,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      isCredit: record.isCredit,
      creditCustomerName: record.creditCustomerName,
      creditDueDate: record.creditDueDate,
      creditPaidAmount: record.creditPaidAmount,
      creditStatus: CreditStatusX.fromDatabase(record.creditStatus),
    );
  }

  Future<bool> recordCreditPayment(
    String transactionId,
    int paymentAmount,
  ) async {
    final transaction = await findById(transactionId);
    if (transaction == null || !transaction.isCredit) return false;

    final newPaidAmount = transaction.creditPaidAmount + paymentAmount;
    final remaining = transaction.amount - newPaidAmount;
    
    String newStatus;
    if (remaining <= 0) {
      newStatus = 'paid';
    } else if (newPaidAmount > 0) {
      newStatus = 'partial';
    } else {
      newStatus = 'pending';
    }

    return _dao.updateTransaction(
      transactionId,
      TransactionsCompanion(
        creditPaidAmount: Value(newPaidAmount),
        creditStatus: Value(newStatus),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

TransactionSqlSort _mapSort(TransactionSort sort) {
  return switch (sort) {
    TransactionSort.newest => TransactionSqlSort.newest,
    TransactionSort.oldest => TransactionSqlSort.oldest,
    TransactionSort.highestAmount => TransactionSqlSort.highestAmount,
    TransactionSort.lowestAmount => TransactionSqlSort.lowestAmount,
  };
}

String? _optionalText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
