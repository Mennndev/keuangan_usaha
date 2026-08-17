import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/currency_text.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
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
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Memuat detail transaksi…'),
          ],
        ),
      ),
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
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: AppPageHeader(
                  title: 'Detail transaksi',
                  subtitle: 'Informasi transaksi usaha',
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
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
