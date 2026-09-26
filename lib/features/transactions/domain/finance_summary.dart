import 'finance_transaction.dart';

class FinanceSummary {
  const FinanceSummary({required this.income, required this.expense});

  final int income;
  final int expense;

  int get balance => income - expense;

  static FinanceSummary fromTransactions(
    Iterable<FinanceTransaction> transactions,
  ) {
    var income = 0;
    var expense = 0;
    for (final transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          income += transaction.amount;
          break;
        case TransactionType.expense:
          expense += transaction.amount;
          break;
      }
    }
    return FinanceSummary(income: income, expense: expense);
  }
}

class PeriodRange {
  const PeriodRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) {
    return other is PeriodRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

class CashFlowPoint {
  const CashFlowPoint({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final int income;
  final int expense;
}

class CashFlowRequest {
  const CashFlowRequest({required this.range, required this.groupByMonth});

  final PeriodRange range;
  final bool groupByMonth;

  @override
  bool operator ==(Object other) {
    return other is CashFlowRequest &&
        other.range == range &&
        other.groupByMonth == groupByMonth;
  }

  @override
  int get hashCode => Object.hash(range, groupByMonth);
}

class CategoryFinanceSummary {
  const CategoryFinanceSummary({
    required this.category,
    required this.amount,
    required this.transactionCount,
  });

  final String category;
  final int amount;
  final int transactionCount;
}

class CategoryReportRequest {
  const CategoryReportRequest({required this.range, required this.type});

  final PeriodRange range;
  final TransactionType type;

  @override
  bool operator ==(Object other) =>
      other is CategoryReportRequest &&
      other.range == range &&
      other.type == type;

  @override
  int get hashCode => Object.hash(range, type);
}
