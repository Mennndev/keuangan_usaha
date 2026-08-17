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
}
