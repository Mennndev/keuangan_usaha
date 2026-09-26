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

enum CreditStatus { pending, partial, paid }

extension CreditStatusX on CreditStatus {
  String get databaseValue => name;

  String get label => switch (this) {
    CreditStatus.pending => 'Belum Dibayar',
    CreditStatus.partial => 'Sebagian Dibayar',
    CreditStatus.paid => 'Lunas',
  };

  static CreditStatus fromDatabase(String value) {
    return switch (value) {
      'pending' => CreditStatus.pending,
      'partial' => CreditStatus.partial,
      'paid' => CreditStatus.paid,
      _ => throw FormatException('Status kredit tidak valid: $value'),
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
    this.isCredit = false,
    this.creditCustomerName,
    this.creditDueDate,
    this.creditPaidAmount = 0,
    this.creditStatus = CreditStatus.pending,
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

  // Credit fields
  final bool isCredit;
  final String? creditCustomerName;
  final DateTime? creditDueDate;
  final int creditPaidAmount;
  final CreditStatus creditStatus;

  int get creditRemainingAmount => amount - creditPaidAmount;

  bool get isCreditPending => isCredit && creditStatus == CreditStatus.pending;
  bool get isCreditPartial => isCredit && creditStatus == CreditStatus.partial;
  bool get isCreditPaid => isCredit && creditStatus == CreditStatus.paid;
}

class TransactionInput {
  const TransactionInput({
    required this.type,
    required this.name,
    required this.amount,
    required this.transactionDate,
    this.category,
    this.notes,
    this.isCredit = false,
    this.creditCustomerName,
    this.creditDueDate,
    this.products = const [],
  });

  final TransactionType type;
  final String name;
  final int amount;
  final String? category;
  final String? notes;
  final DateTime transactionDate;

  // Credit fields
  final bool isCredit;
  final String? creditCustomerName;
  final DateTime? creditDueDate;
  final List<TransactionProductInput> products;
}

class TransactionProductInput {
  const TransactionProductInput({
    required this.productId,
    required this.quantity,
  });

  final String productId;
  final int quantity;
}
