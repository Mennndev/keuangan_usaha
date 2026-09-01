import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatters/currency_formatter.dart';
import '../../domain/finance_transaction.dart';
import '../providers/transaction_providers.dart';

class CreditPaymentDialog extends ConsumerStatefulWidget {
  const CreditPaymentDialog({
    required this.transaction,
    super.key,
  });

  final FinanceTransaction transaction;

  @override
  ConsumerState<CreditPaymentDialog> createState() =>
      _CreditPaymentDialogState();
}

class _CreditPaymentDialogState extends ConsumerState<CreditPaymentDialog> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: CurrencyFormatter.digits(widget.transaction.creditRemainingAmount),
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    final amount = CurrencyFormatter.parse(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal pembayaran harus lebih dari 0')),
      );
      return;
    }

    if (amount > widget.transaction.creditRemainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal pembayaran melebihi sisa cicilan'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final controller = ref.read(transactionControllerProvider.notifier);
      await controller.recordCreditPayment(widget.transaction.id, amount);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran kredit berhasil dicatat')),
      );
      Navigator.of(context).pop();
      ref.invalidate(creditsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencatat pembayaran: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.transaction.creditRemainingAmount;

    return AlertDialog(
      title: const Text('Catat Pembayaran Kredit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pelanggan: ${widget.transaction.creditCustomerName}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Sisa Cicilan: ${CurrencyFormatter.format(remaining)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nominal Pembayaran',
                prefixText: 'Rp ',
                hintText: '0',
                border: const OutlineInputBorder(),
              ),
              inputFormatters: [RupiahInputFormatter()],
              enabled: !_submitting,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Contoh: Pembayaran cicilan 1',
                border: const OutlineInputBorder(),
              ),
              enabled: !_submitting,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_submitting ? 'Menyimpan…' : 'Simpan'),
        ),
      ],
    );
  }
}
