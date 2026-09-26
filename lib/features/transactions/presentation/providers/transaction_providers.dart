import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../../database/database_provider.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/product_dao.dart';
import '../../data/transaction_repository.dart';
import '../../domain/finance_summary.dart';
import '../../domain/finance_transaction.dart';
import '../../domain/transaction_filter.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return TransactionRepository(
    database,
    database.transactionDao,
    database.productDao,
  );
});

final transactionsProvider = StreamProvider.autoDispose
    .family<List<FinanceTransaction>, TransactionFilter>((ref, filter) {
      return ref.watch(transactionRepositoryProvider).watchFiltered(filter);
    });

final latestTransactionsProvider = StreamProvider.autoDispose
    .family<List<FinanceTransaction>, int>((ref, limit) {
      return ref.watch(transactionRepositoryProvider).watchLatest(limit: limit);
    });

final transactionByIdProvider = StreamProvider.autoDispose
    .family<FinanceTransaction?, String>((ref, id) {
      return ref.watch(transactionRepositoryProvider).watchById(id);
    });

final financeTotalsProvider = StreamProvider.autoDispose
    .family<FinanceSummary, PeriodRange>((ref, range) {
      return ref.watch(transactionRepositoryProvider).watchTotals(range);
    });

final allTimeFinanceTotalsProvider = StreamProvider.autoDispose<FinanceSummary>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAllTimeTotals(),
);

final cashFlowProvider = StreamProvider.autoDispose
    .family<List<CashFlowPoint>, CashFlowRequest>((ref, request) {
      return ref.watch(transactionRepositoryProvider).watchCashFlow(request);
    });

final categoryTotalsProvider = StreamProvider.autoDispose
    .family<List<CategoryFinanceSummary>, CategoryReportRequest>((
      ref,
      request,
    ) {
      return ref
          .watch(transactionRepositoryProvider)
          .watchCategoryTotals(request);
    });

final creditsProvider = FutureProvider.autoDispose<List<FinanceTransaction>>(
  (ref) =>
      ref.watch(transactionRepositoryProvider).getCredits(includePaid: true),
);

final creditPaymentHistoryProvider = StreamProvider.autoDispose
    .family<List<CreditPaymentRecord>, String>((ref, transactionId) {
      final database = ref.watch(databaseProvider);
      return (database.select(database.creditPayments)
            ..where((payment) => payment.transactionId.equals(transactionId))
            ..orderBy([(payment) => OrderingTerm.desc(payment.paymentDate)]))
          .watch();
    });

final productSaleProvider = FutureProvider.autoDispose
    .family<List<ProductSaleSnapshot>, String>((ref, transactionId) {
      return ref
          .watch(databaseProvider)
          .productDao
          .salesForTransaction(transactionId);
    });

final transactionControllerProvider =
    AsyncNotifierProvider<TransactionController, void>(
      TransactionController.new,
    );

class TransactionController extends AsyncNotifier<void> {
  TransactionRepository get _repository =>
      ref.read(transactionRepositoryProvider);

  @override
  FutureOr<void> build() {}

  Future<String> create(TransactionInput input) async {
    _guardDoubleSubmit();
    state = const AsyncLoading();
    try {
      final id = await _repository.create(input);
      state = const AsyncData(null);
      return id;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> edit(String id, TransactionInput input) async {
    _guardDoubleSubmit();
    state = const AsyncLoading();
    try {
      final updated = await _repository.update(id, input);
      if (!updated) {
        throw StateError('Transaksi tidak ditemukan.');
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    _guardDoubleSubmit();
    state = const AsyncLoading();
    try {
      final deleted = await _repository.delete(id);
      if (!deleted) {
        throw StateError('Transaksi tidak ditemukan.');
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> recordCreditPayment(
    String transactionId,
    int paymentAmount, {
    String? notes,
  }) async {
    _guardDoubleSubmit();
    state = const AsyncLoading();
    try {
      final updated = await _repository.recordCreditPayment(
        transactionId,
        paymentAmount,
        notes: notes,
      );
      if (!updated) {
        throw StateError('Transaksi kredit tidak ditemukan.');
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _guardDoubleSubmit() {
    if (state.isLoading) {
      throw StateError('Permintaan sedang diproses.');
    }
  }
}
