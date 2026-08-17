import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _digits = NumberFormat.decimalPattern('id_ID');

  static String format(int amount) => _formatter.format(amount);

  static String formatSigned(int amount, {required bool income}) {
    return '${income ? '+' : '-'} ${format(amount)}';
  }

  static String digits(int amount) => _digits.format(amount);

  static int parse(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }
}

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final value = int.tryParse(digits);
    if (value == null) return oldValue;
    final formatted = CurrencyFormatter.digits(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
