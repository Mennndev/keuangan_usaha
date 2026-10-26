import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/core/formatters/currency_formatter.dart';
import 'package:keuangan_usaha/features/transactions/domain/transaction_validators.dart';

void main() {
  test('memformat rupiah integer tanpa desimal', () {
    expect(CurrencyFormatter.format(24500000), 'Rp 24.500.000');
    expect(CurrencyFormatter.parse('24.500.000'), 24500000);
  });

  test('memvalidasi nominal harus lebih besar dari nol', () {
    expect(TransactionValidators.amount('0'), isNotNull);
    expect(TransactionValidators.amount(''), isNotNull);
    expect(TransactionValidators.amount('125.000'), isNull);
  });

  test('memvalidasi nama kosong atau hanya spasi', () {
    expect(TransactionValidators.name(''), isNotNull);
    expect(TransactionValidators.name('   '), isNotNull);
    expect(TransactionValidators.name('Penjualan'), isNull);
  });

  group('CurrencyFormatter.formatSigned', () {
    test('menambahkan tanda plus untuk pemasukan', () {
      expect(
        CurrencyFormatter.formatSigned(150000, income: true),
        '+ Rp 150.000',
      );
    });

    test('menambahkan tanda minus untuk pengeluaran', () {
      expect(
        CurrencyFormatter.formatSigned(150000, income: false),
        '- Rp 150.000',
      );
    });

    test('mengabaikan tanda negatif pada nominal', () {
      expect(
        CurrencyFormatter.formatSigned(-150000, income: true),
        '+ Rp 150.000',
      );
      expect(
        CurrencyFormatter.formatSigned(-150000, income: false),
        '- Rp 150.000',
      );
    });
  });

  group('RupiahInputFormatter', () {
    final formatter = RupiahInputFormatter();

    test('memformat digit menjadi pemisah ribuan', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '150000'),
      );

      expect(result.text, '150.000');
      expect(result.selection, const TextSelection.collapsed(offset: 7));
    });

    test('mengabaikan karakter non-digit sebelum memformat', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: 'Rp 150.000'),
      );

      expect(result.text, '150.000');
    });

    test('mengosongkan nilai saat input dikosongkan', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '150.000'),
        TextEditingValue.empty,
      );

      expect(result.text, isEmpty);
    });
  });
}
