enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get databaseValue => name;

  String get label => switch (this) {
    TransactionType.income => 'Pemasukan',
    TransactionType.expense => 'Pengeluaran',
  };

  String get signedPrefix => switch (this) {
    TransactionType.income => '+',
    TransactionType.expense => '-',
  };

  static TransactionType fromDatabase(String value) {
    return switch (value) {
      'income' => TransactionType.income,
      'expense' => TransactionType.expense,
      _ => throw FormatException('Jenis transaksi tidak valid: $value'),
    };
  }
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.notes,
  });

  final String id;
  final TransactionType type;
  final String name;
  final int amount;
  final String? category;
  final String? notes;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class TransactionInput {
  const TransactionInput({
    required this.type,
    required this.name,
    required this.amount,
    required this.transactionDate,
    this.category,
    this.notes,
  });

  final TransactionType type;
  final String name;
  final int amount;
  final String? category;
  final String? notes;
  final DateTime transactionDate;
}
