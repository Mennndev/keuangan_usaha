class TransactionValidators {
  const TransactionValidators._();

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama transaksi wajib diisi.';
    }
    return null;
  }

  static String? amount(String? value) {
    final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final amount = int.tryParse(digits);
    if (amount == null || amount <= 0) {
      return 'Nominal harus lebih besar dari Rp 0.';
    }
    return null;
  }
}
