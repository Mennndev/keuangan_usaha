import 'package:flutter/services.dart';

/// Membatasi input menjadi digit angka saja.
///
/// Dipakai untuk nominal stok agar pengguna tidak dapat mengetik tanda negatif,
/// huruf, atau pemisah yang tidak valid.
class NumberInputFormatter extends TextInputFormatter {
  const NumberInputFormatter({this.maxDigits});

  final int? maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Tolak tanda negatif alih-alih membuangnya, agar "-5" tidak berubah
    // diam-diam menjadi stok 5.
    if (newValue.text.contains('-')) return oldValue;
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limit = maxDigits;
    if (limit != null && digits.length > limit) {
      digits = digits.substring(0, limit);
    }
    if (digits.isEmpty) return const TextEditingValue();
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
