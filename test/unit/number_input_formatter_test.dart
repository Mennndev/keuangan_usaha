import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/core/formatters/number_input_formatter.dart';

void main() {
  const formatter = NumberInputFormatter();

  TextEditingValue apply(String text) => formatter.formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(text: text),
  );

  test('menolak tanda negatif tanpa mengubahnya menjadi positif', () {
    expect(apply('-12').text, '');
    expect(apply('1a2b').text, '12');
    expect(apply('').text, '');
  });

  test('tanda negatif tidak menghapus angka yang sudah diketik', () {
    const oldValue = TextEditingValue(text: '5');
    final value = formatter.formatEditUpdate(
      oldValue,
      const TextEditingValue(text: '5-'),
    );
    expect(value.text, '5');
  });

  test('membatasi jumlah digit bila maxDigits diisi', () {
    const limited = NumberInputFormatter(maxDigits: 3);
    final value = limited.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '12345'),
    );
    expect(value.text, '123');
    expect(value.selection.baseOffset, 3);
  });
}
