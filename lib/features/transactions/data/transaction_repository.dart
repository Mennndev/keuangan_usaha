import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/app_database.dart';
import '../../../database/daos/product_dao.dart';
import '../../../database/daos/transaction_dao.dart';
import '../domain/finance_summary.dart';
import '../domain/finance_transaction.dart';
import '../domain/transaction_filter.dart';

class TransactionRepository {
  TransactionRepository(
    this._database,
    this._dao,
    this._productDao, {
    this._uuid = const Uuid(),
  });

  final AppDatabase _database;
  final TransactionDao _dao;
  final ProductDao _productDao;
  final Uuid _uuid;

  Future<String> create(TransactionInput input) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    return _database.transaction(() async {
      final saleLines = await _resolveSaleLines(input);
      await _dao.insertTransaction(
        TransactionsCompanion.insert(
          id: id,
          type: input.type.databaseValue,
          name: input.name.trim(),
          amount: _transactionAmount(input.amount, saleLines),
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
      for (final line in saleLines) {
        await _productDao.recordSale(
          productId: line.product.id,
          quantity: line.quantity,
          date: input.transactionDate,
          transactionId: id,
          snapshotUnitPrice: line.unitPrice,
        );
      }
      return id;
    });
  }

  Future<bool> update(String id, TransactionInput input) async {
    return _database.transaction(() async {
      final existing = await _dao.findById(id);
      if (existing == null) return false;
      final previousSales = await _productDao.salesForTransaction(id);
      for (final sale in previousSales) {
        await _productDao.restoreSale(
          sale,
          transactionId: id,
          date: DateTime.now(),
        );
      }
      final saleLines = await _resolveSaleLines(
        input,
        previousSales: previousSales,
      );
      final updated = await _dao.updateTransaction(
        id,
        TransactionsCompanion(
          type: Value(input.type.databaseValue),
          name: Value(input.name.trim()),
          amount: Value(_transactionAmount(input.amount, saleLines)),
          category: Value(_optionalText(input.category)),
          notes: Value(_optionalText(input.notes)),
          transactionDate: Value(input.transactionDate),
          updatedAt: Value(DateTime.now()),
          isCredit: Value(input.isCredit),
          creditCustomerName: Value(_optionalText(input.creditCustomerName)),
          creditDueDate: Value(input.creditDueDate),
        ),
      );
      if (updated) {
        for (final line in saleLines) {
          await _productDao.recordSale(
            productId: line.product.id,
            quantity: line.quantity,
            date: input.transactionDate,
            transactionId: id,
            snapshotUnitPrice: line.unitPrice,
          );
        }
      }
      return updated;
    });
  }

  Future<bool> delete(String id) async {
    return _database.transaction(() async {
      final sales = await _productDao.salesForTransaction(id);
      for (final sale in sales) {
        await _productDao.restoreSale(
          sale,
          transactionId: id,
          date: DateTime.now(),
        );
      }
      return _dao.deleteTransaction(id);
    });
  }

  Future<FinanceTransaction?> findById(String id) async {
    final record = await _dao.findById(id);
    return record == null ? null : _map(record);
  }

  Stream<FinanceTransaction?> watchById(String id) =>
      _dao.watchById(id).map((record) => record == null ? null : _map(record));

  Stream<List<FinanceTransaction>> watchFiltered(TransactionFilter filter) =>
      _dao
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

  Stream<List<FinanceTransaction>> watchLatest({int limit = 5}) =>
      watchFiltered(TransactionFilter(limit: limit));

  Stream<FinanceSummary> watchTotals(PeriodRange range) => _dao
      .watchTotals(start: range.start, end: range.end)
      .map(
        (record) =>
            FinanceSummary(income: record.income, expense: record.expense),
      );

  Stream<FinanceSummary> watchAllTimeTotals() => _dao.watchAllTimeTotals().map(
    (record) => FinanceSummary(income: record.income, expense: record.expense),
  );

  Stream<List<CashFlowPoint>> watchCashFlow(CashFlowRequest request) => _dao
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

  Stream<List<CategoryFinanceSummary>> watchCategoryTotals(
    CategoryReportRequest request,
  ) => _dao
      .watchCategoryTotals(
        start: request.range.start,
        end: request.range.end,
        type: request.type.databaseValue,
      )
      .map(
        (records) => records
            .map(
              (record) => CategoryFinanceSummary(
                category: record.category,
                amount: record.amount,
                transactionCount: record.transactionCount,
              ),
            )
            .toList(growable: false),
      );

  Future<List<FinanceTransaction>> getAll() async =>
      (await _dao.getAllTransactions()).map(_map).toList(growable: false);

  Future<List<FinanceTransaction>> getCredits({
    bool includePaid = false,
  }) async => (await _dao.getAllTransactions())
      .where((r) => r.isCredit)
      .where((r) => includePaid || r.creditStatus != 'paid')
      .map(_map)
      .toList(growable: false);

  FinanceTransaction _map(TransactionRecord record) => FinanceTransaction(
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

  Future<bool> recordCreditPayment(
    String transactionId,
    int paymentAmount, {
    String? notes,
  }) async {
    return _database.transaction(() async {
      final transaction = await findById(transactionId);
      if (transaction == null ||
          !transaction.isCredit ||
          paymentAmount <= 0 ||
          paymentAmount > transaction.creditRemainingAmount)
        return false;
      final newPaidAmount = transaction.creditPaidAmount + paymentAmount;
      final remaining = transaction.amount - newPaidAmount;
      final status = remaining <= 0
          ? 'paid'
          : (newPaidAmount > 0 ? 'partial' : 'pending');
      final updated = await _dao.updateTransaction(
        transactionId,
        TransactionsCompanion(
          creditPaidAmount: Value(newPaidAmount),
          creditStatus: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );
      if (updated) {
        final now = DateTime.now();
        await _database
            .into(_database.creditPayments)
            .insert(
              CreditPaymentsCompanion.insert(
                id: _uuid.v4(),
                transactionId: transactionId,
                paymentAmount: paymentAmount,
                paymentDate: now,
                notes: Value(_optionalText(notes)),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
      return updated;
    });
  }

  Future<List<_PricedSaleLine>> _resolveSaleLines(
    TransactionInput input, {
    List<ProductSaleSnapshot> previousSales = const [],
  }) async {
    if (input.products.isNotEmpty && input.type != TransactionType.income) {
      throw ArgumentError('Produk hanya dapat dipilih untuk pemasukan.');
    }
    final previousByProduct = {
      for (final sale in previousSales) sale.productId: sale,
    };
    final seenProductIds = <String>{};
    final lines = <_PricedSaleLine>[];
    for (final item in input.products) {
      if (item.quantity <= 0) {
        throw ArgumentError('Jumlah setiap produk harus lebih dari 0.');
      }
      if (!seenProductIds.add(item.productId)) {
        throw ArgumentError(
          'Produk yang sama tidak boleh ditambahkan dua kali.',
        );
      }
      final product = await _productDao.findProduct(item.productId);
      if (product == null) throw StateError('Produk tidak ditemukan.');
      if (product.stockQuantity < item.quantity) {
        throw StateError('Stok ${product.name} tidak mencukupi.');
      }
      final previous = previousByProduct[item.productId];
      final unitPrice = previous != null && previous.quantity == item.quantity
          ? previous.unitPrice
          : product.sellingPrice;
      lines.add(
        _PricedSaleLine(
          product: product,
          quantity: item.quantity,
          unitPrice: unitPrice,
        ),
      );
    }
    return lines;
  }

  int _transactionAmount(int manualAmount, List<_PricedSaleLine> saleLines) {
    if (saleLines.isEmpty) return manualAmount;
    return saleLines.fold(
      0,
      (total, line) => total + line.unitPrice * line.quantity,
    );
  }
}

class _PricedSaleLine {
  const _PricedSaleLine({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  final ProductRow product;
  final int quantity;
  final int unitPrice;
}

TransactionSqlSort _mapSort(TransactionSort sort) => switch (sort) {
  TransactionSort.newest => TransactionSqlSort.newest,
  TransactionSort.oldest => TransactionSqlSort.oldest,
  TransactionSort.highestAmount => TransactionSqlSort.highestAmount,
  TransactionSort.lowestAmount => TransactionSqlSort.lowestAmount,
};

String? _optionalText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
