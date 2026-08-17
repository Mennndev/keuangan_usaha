import 'finance_transaction.dart';

enum TransactionSort { newest, oldest, highestAmount, lowestAmount }

extension TransactionSortX on TransactionSort {
  String get label => switch (this) {
    TransactionSort.newest => 'Terbaru',
    TransactionSort.oldest => 'Terlama',
    TransactionSort.highestAmount => 'Nominal terbesar',
    TransactionSort.lowestAmount => 'Nominal terkecil',
  };
}

class TransactionFilter {
  const TransactionFilter({
    this.search = '',
    this.type,
    this.start,
    this.end,
    this.sort = TransactionSort.newest,
    this.limit = 30,
    this.offset = 0,
  });

  final String search;
  final TransactionType? type;
  final DateTime? start;
  final DateTime? end;
  final TransactionSort sort;
  final int limit;
  final int offset;

  TransactionFilter copyWith({
    String? search,
    TransactionType? type,
    bool clearType = false,
    DateTime? start,
    DateTime? end,
    bool clearDates = false,
    TransactionSort? sort,
    int? limit,
    int? offset,
  }) {
    return TransactionFilter(
      search: search ?? this.search,
      type: clearType ? null : type ?? this.type,
      start: clearDates ? null : start ?? this.start,
      end: clearDates ? null : end ?? this.end,
      sort: sort ?? this.sort,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionFilter &&
        other.search == search &&
        other.type == type &&
        other.start == start &&
        other.end == end &&
        other.sort == sort &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode =>
      Object.hash(search, type, start, end, sort, limit, offset);
}

List<FinanceTransaction> filterAndSortTransactions(
  Iterable<FinanceTransaction> source,
  TransactionFilter filter,
) {
  final needle = filter.search.trim().toLowerCase();
  final result = source.where((transaction) {
    if (filter.type != null && transaction.type != filter.type) {
      return false;
    }
    if (filter.start != null &&
        transaction.transactionDate.isBefore(filter.start!)) {
      return false;
    }
    if (filter.end != null &&
        !transaction.transactionDate.isBefore(filter.end!)) {
      return false;
    }
    if (needle.isEmpty) {
      return true;
    }
    return transaction.name.toLowerCase().contains(needle) ||
        (transaction.category?.toLowerCase().contains(needle) ?? false) ||
        (transaction.notes?.toLowerCase().contains(needle) ?? false);
  }).toList();

  result.sort((a, b) {
    return switch (filter.sort) {
      TransactionSort.newest => b.transactionDate.compareTo(a.transactionDate),
      TransactionSort.oldest => a.transactionDate.compareTo(b.transactionDate),
      TransactionSort.highestAmount => b.amount.compareTo(a.amount),
      TransactionSort.lowestAmount => a.amount.compareTo(b.amount),
    };
  });
  return result;
}
