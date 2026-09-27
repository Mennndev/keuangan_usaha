import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/currency_text.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/transaction_type_badge.dart';
import '../../domain/finance_transaction.dart';
import '../providers/transaction_providers.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.transactionId, super.key});

  final String transactionId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FinanceTransaction transaction,
  ) async {
    final deleted = await showConfirmDeleteDialog(
      context,
      transactionName: transaction.name,
      onDelete: () => ref
          .read(transactionControllerProvider.notifier)
          .delete(transaction.id),
    );
    if (!context.mounted || !deleted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil dihapus.')),
    );
    context.go('/transactions');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = ref.watch(transactionByIdProvider(transactionId));
    return transaction.when(
      loading: () => const AppLoadingState(message: 'Memuat detail transaksi…'),
      error: (error, stackTrace) => ErrorState(
        message: 'Detail transaksi belum dapat dimuat.',
        onRetry: () => ref.invalidate(transactionByIdProvider(transactionId)),
      ),
      data: (value) {
        if (value == null) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Transaksi tidak ditemukan',
            message: 'Transaksi mungkin sudah dihapus dari perangkat ini.',
            primaryAction: FilledButton(
              onPressed: () => context.go('/transactions'),
              child: const Text('Kembali ke transaksi'),
            ),
          );
        }
        final paymentHistory = value.isCredit
            ? ref.watch(creditPaymentHistoryProvider(value.id))
            : null;
        final productSales = value.type == TransactionType.income
            ? ref.watch(productSaleProvider(value.id))
            : null;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: AppPageHeader(
                  title: 'Detail transaksi',
                  leading: IconButton(
                    tooltip: 'Kembali',
                    onPressed: () => context.go('/transactions'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    value.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TransactionTypeBadge(type: value.type),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: CurrencyText(
                                amount: value.amount,
                                type: value.type,
                                showSign: true,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _DetailRow(
                              label: 'Tanggal',
                              value: AppDateFormatter.long(
                                value.transactionDate,
                              ),
                            ),
                            if (value.category != null)
                              _DetailRow(
                                label: 'Kategori',
                                value: value.category!,
                              ),
                            if (value.notes != null)
                              _DetailRow(
                                label: 'Keterangan',
                                value: value.notes!,
                              ),
                            if (!value.isCredit &&
                                value.creditCustomerName != null)
                              _DetailRow(
                                label: 'Pelanggan',
                                value: value.creditCustomerName!,
                              ),
                            if (productSales != null) ...[
                              const Divider(height: 32),
                              Text(
                                'Produk terjual',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              productSales.when(
                                loading: () => const AppLoadingState(
                                  compact: true,
                                  message: 'Memuat produk terjual…',
                                ),
                                error: (error, stack) => ErrorState(
                                  compact: true,
                                  message:
                                      'Daftar produk transaksi belum dapat dimuat.',
                                  onRetry: () => ref.invalidate(
                                    productSaleProvider(value.id),
                                  ),
                                ),
                                data: (sales) => sales.isEmpty
                                    ? const Text(
                                        'Transaksi tanpa produk terdaftar.',
                                      )
                                    : Column(
                                        children: sales
                                            .map(
                                              (sale) => ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                title: Text(
                                                  '${sale.productName} · ${sale.brand}',
                                                ),
                                                subtitle: Text(
                                                  '${sale.quantity} × ${CurrencyFormatter.format(sale.unitPrice)}',
                                                ),
                                                trailing: Text(
                                                  CurrencyFormatter.format(
                                                    sale.quantity *
                                                        sale.unitPrice,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                              ),
                            ],
                            if (value.isCredit) ...[
                              const Divider(height: 32),
                              Text(
                                'Informasi Kredit',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              _DetailRow(
                                label: 'Nama Pelanggan',
                                value: value.creditCustomerName ?? '-',
                              ),
                              _DetailRow(
                                label: 'Status',
                                value: '',
                                valueWidget: CreditStatusBadge(
                                  status: value.creditStatus,
                                  isOverdue: _isOverdueCredit(value),
                                ),
                              ),
                              _DetailRow(
                                label: 'Jatuh Tempo',
                                value: AppDateFormatter.long(
                                  value.creditDueDate ?? value.transactionDate,
                                ),
                              ),
                              _DetailRow(
                                label: 'Total Kredit',
                                value:
                                    'Rp ${value.amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                              ),
                              _DetailRow(
                                label: 'Sudah Dibayar',
                                value:
                                    'Rp ${value.creditPaidAmount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                              ),
                              _DetailRow(
                                label: 'Sisa Cicilan',
                                value:
                                    'Rp ${value.creditRemainingAmount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                              ),
                              const Divider(height: 32),
                              Text(
                                'Riwayat pembayaran',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              paymentHistory!.when(
                                loading: () => const AppLoadingState(
                                  compact: true,
                                  message: 'Memuat pembayaran…',
                                ),
                                error: (error, stack) => ErrorState(
                                  compact: true,
                                  message:
                                      'Riwayat pembayaran belum dapat dimuat.',
                                  onRetry: () => ref.invalidate(
                                    creditPaymentHistoryProvider(value.id),
                                  ),
                                ),
                                data: (payments) => payments.isEmpty
                                    ? const Text(
                                        'Belum ada pembayaran yang dicatat.',
                                      )
                                    : Column(
                                        children: payments
                                            .map(
                                              (payment) => ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                leading: const Icon(
                                                  Icons.payments_outlined,
                                                ),
                                                title: Text(
                                                  CurrencyFormatter.format(
                                                    payment.paymentAmount,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '${AppDateFormatter.long(payment.paymentDate)}${payment.notes == null ? '' : ' · ${payment.notes}'}',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                              ),
                            ],
                            _DetailRow(
                              label: 'Dibuat',
                              value: AppDateFormatter.dateTime(value.createdAt),
                            ),
                            _DetailRow(
                              label: 'Terakhir diperbarui',
                              value: AppDateFormatter.dateTime(value.updatedAt),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => context.go(
                                    '/transactions/${value.id}/edit',
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit transaksi'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _delete(context, ref, value),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Hapus'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
          final valueContent = valueWidget ?? Text(value);
          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: 4),
                valueContent,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 148, child: Text(label, style: labelStyle)),
              Expanded(child: valueContent),
            ],
          );
        },
      ),
    );
  }
}

bool _isOverdueCredit(FinanceTransaction transaction) {
  final due = transaction.creditDueDate;
  if (!transaction.isCredit ||
      transaction.creditRemainingAmount <= 0 ||
      due == null) {
    return false;
  }
  final now = DateTime.now();
  return DateTime(
    due.year,
    due.month,
    due.day,
  ).isBefore(DateTime(now.year, now.month, now.day));
}
