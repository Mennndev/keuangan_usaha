import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/finance_transaction.dart';
import '../providers/transaction_providers.dart';
import 'credit_payment_screen.dart';

class CreditsScreen extends ConsumerStatefulWidget {
  const CreditsScreen({super.key});

  @override
  ConsumerState<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends ConsumerState<CreditsScreen> {
  String _filterStatus = 'all'; // all, pending, partial, paid

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(creditsProvider);

    return creditsAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Memuat daftar kredit…'),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: ErrorState(
          message: 'Daftar kredit belum dapat dibuka.',
          onRetry: () => ref.invalidate(creditsProvider),
        ),
      ),
      data: (credits) {
        final filtered = _filterCredits(credits, _filterStatus);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Penjualan Kredit'),
            centerTitle: false,
            elevation: 0,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Belum Dibayar', 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Sebagian', 'partial'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Lunas', 'paid'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _filterStatus == 'all'
                              ? 'Tidak ada transaksi kredit'
                              : 'Tidak ada transaksi kredit dengan status ini',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final credit = filtered[index];
                          return _buildCreditCard(context, credit);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String status) {
    return FilterChip(
      label: Text(label),
      selected: _filterStatus == status,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
    );
  }

  Widget _buildCreditCard(BuildContext context, FinanceTransaction credit) {
    final remaining = credit.creditRemainingAmount;
    final isPending = credit.creditStatus == CreditStatus.pending;
    final isPartial = credit.creditStatus == CreditStatus.partial;
    final isPaid = credit.creditStatus == CreditStatus.paid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credit.creditCustomerName ?? 'Pelanggan',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        credit.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(credit.creditStatus.label),
                  backgroundColor: _getStatusColor(credit.creditStatus),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      CurrencyFormatter.format(credit.amount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sudah Dibayar',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      CurrencyFormatter.format(credit.creditPaidAmount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
                if (remaining > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sisa',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        CurrencyFormatter.format(remaining),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: isPaid ? Colors.green : Colors.orange,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jatuh Tempo',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      AppDateFormatter.long(
                        credit.creditDueDate ?? credit.transactionDate,
                      ),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/transactions/${credit.id}',
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Detail'),
                    ),
                    const SizedBox(width: 8),
                    if (!isPaid)
                      FilledButton.icon(
                        onPressed: () => _showPaymentDialog(context, credit),
                        icon: const Icon(Icons.payment_outlined),
                        label: const Text('Bayar'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<FinanceTransaction> _filterCredits(
    List<FinanceTransaction> credits,
    String status,
  ) {
    if (status == 'all') return credits;
    return credits
        .where((c) => c.creditStatus.databaseValue == status)
        .toList();
  }

  Color _getStatusColor(CreditStatus status) {
    return switch (status) {
      CreditStatus.pending => Colors.red,
      CreditStatus.partial => Colors.orange,
      CreditStatus.paid => Colors.green,
    };
  }

  void _showPaymentDialog(BuildContext context, FinanceTransaction credit) {
    showDialog<void>(
      context: context,
      builder: (context) => CreditPaymentDialog(transaction: credit),
    );
  }
}
