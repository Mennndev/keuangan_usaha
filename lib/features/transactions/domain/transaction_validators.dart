import '../../../core/formatters/currency_formatter.dart';

class TransactionValidators {
  const TransactionValidators._();

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama transaksi wajib diisi.';
    }
    return null;
  }

  static String? amount(String? value) {
    final amount = CurrencyFormatter.parse(value ?? '');
    if (amount <= 0) {
      return 'Nominal harus lebih besar dari Rp 0.';
    }
    return null;
  }
}
