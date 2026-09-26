import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/empty_state.dart';
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
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(creditsProvider);

    return creditsAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Memuat daftar kredit…'),
          ],
        ),
      ),
      error: (error, stackTrace) => ErrorState(
        message: 'Daftar kredit belum dapat dibuka.',
        onRetry: () => ref.invalidate(creditsProvider),
      ),
      data: (credits) => _buildContent(context, credits),
    );
  }

  Widget _buildContent(BuildContext context, List<FinanceTransaction> credits) {
    final filtered = _filterCredits(credits, _filterStatus);
    final total = credits.fold<int>(0, (sum, item) => sum + item.amount);
    final paid = credits.fold<int>(
      0,
      (sum, item) => sum + item.creditPaidAmount,
    );
    final remaining = credits.fold<int>(
      0,
      (sum, item) => sum + item.creditRemainingAmount,
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: AppPageHeader(
              title: 'Kredit',
              subtitle: 'Pantau tagihan pelanggan dan pembayaran yang masuk',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 760
                            ? 3
                            : constraints.maxWidth >= 480
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - ((columns - 1) * 12)) /
                            columns;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: width,
                              child: _CreditSummaryCard(
                                label: 'Total kredit',
                                amount: total,
                                icon: Icons.receipt_long_outlined,
                                tone: _CreditSummaryTone.info,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _CreditSummaryCard(
                                label: 'Sudah dibayar',
                                amount: paid,
                                icon: Icons.check_circle_outline_rounded,
                                tone: _CreditSummaryTone.paid,
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: _CreditSummaryCard(
                                label: 'Sisa tagihan',
                                amount: remaining,
                                icon: Icons.pending_actions_outlined,
                                tone: _CreditSummaryTone.remaining,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    ..._dueReminderWidgets(context, credits),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Daftar kredit',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          '${filtered.length} transaksi',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Semua', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Belum dibayar', 'pending'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Sebagian', 'partial'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Lunas', 'paid'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      EmptyState(
                        icon: Icons.credit_card_off_outlined,
                        title: _filterStatus == 'all'
                            ? 'Belum ada transaksi kredit'
                            : 'Tidak ada kredit dengan status ini',
                        message: _filterStatus == 'all'
                            ? 'Transaksi pemasukan dengan metode kredit akan muncul di sini.'
                            : 'Coba pilih status lain untuk melihat transaksi kredit.',
                        primaryAction: _filterStatus == 'all'
                            ? FilledButton.icon(
                                onPressed: () =>
                                    context.go('/transactions/new?type=income'),
                                icon: const Icon(Icons.add),
                                label: const Text('Catat pemasukan'),
                              )
                            : null,
                      )
                    else
                      ...filtered.map(
                        (credit) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildCreditCard(context, credit),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _dueReminderWidgets(
    BuildContext context,
    List<FinanceTransaction> credits,
  ) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final limit = start.add(const Duration(days: 7));
    final active = credits.where(
      (c) => c.creditRemainingAmount > 0 && c.creditDueDate != null,
    );
    final overdue = active
        .where((c) => c.creditDueDate!.isBefore(start))
        .toList();
    final dueSoon = active
        .where(
          (c) =>
              !c.creditDueDate!.isBefore(start) &&
              c.creditDueDate!.isBefore(limit.add(const Duration(days: 1))),
        )
        .toList();
    if (overdue.isEmpty && dueSoon.isEmpty) return const [];
    final color = overdue.isNotEmpty
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.tertiary;
    return [
      const SizedBox(height: 14),
      Card(
        color: color.withValues(alpha: .08),
        child: ExpansionTile(
          leading: Icon(Icons.notifications_active_outlined, color: color),
          title: Text(
            '${overdue.length} terlambat · ${dueSoon.length} jatuh tempo 7 hari ini',
          ),
          subtitle: const Text('Pengingat tagihan yang masih memiliki sisa'),
          children: [
            for (final item in [...overdue, ...dueSoon])
              ListTile(
                title: Text(item.creditCustomerName ?? item.name),
                subtitle: Text(
                  '${item.name} · ${item.creditDueDate == null ? '' : AppDateFormatter.long(item.creditDueDate!)}',
                ),
                trailing: Text(
                  CurrencyFormatter.format(item.creditRemainingAmount),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  Widget _buildFilterChip(String label, String status) {
    return ChoiceChip(
      label: Text(label),
      selected: _filterStatus == status,
      onSelected: (_) => setState(() => _filterStatus = status),
    );
  }

  Widget _buildCreditCard(BuildContext context, FinanceTransaction credit) {
    final remaining = credit.creditRemainingAmount;
    final isPaid = credit.creditStatus == CreditStatus.paid;
    final color = _getStatusColor(context, credit.creditStatus);
    final paidProgress = credit.amount <= 0
        ? 0.0
        : (credit.creditPaidAmount / credit.amount).clamp(0.0, 1.0).toDouble();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          foregroundColor: color,
          child: const Icon(Icons.person_outline_rounded),
        ),
        title: Text(
          credit.creditCustomerName ?? 'Pelanggan',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                credit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _CreditStatusBadge(status: credit.creditStatus, color: color),
                  Text(
                    'Sisa ${CurrencyFormatter.format(remaining)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: remaining == 0
                          ? context.appColors.income
                          : context.appColors.expense,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.centerLeft,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              final stats = [
                _CreditAmount(label: 'Total kredit', amount: credit.amount),
                _CreditAmount(
                  label: 'Sudah dibayar',
                  amount: credit.creditPaidAmount,
                ),
                _CreditAmount(
                  label: 'Sisa tagihan',
                  amount: remaining,
                  emphasized: true,
                ),
              ];
              if (compact) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: stats[0]),
                        Expanded(child: stats[1]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(children: [Expanded(child: stats[2])]),
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: stats[i]),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: paidProgress,
              minHeight: 6,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Jatuh tempo ${AppDateFormatter.short(credit.creditDueDate ?? credit.transactionDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/transactions/${credit.id}'),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Detail transaksi'),
              ),
              if (!isPaid)
                FilledButton.icon(
                  onPressed: () => _showPaymentDialog(context, credit),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Catat pembayaran'),
                ),
            ],
          ),
        ],
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

  Color _getStatusColor(BuildContext context, CreditStatus status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      CreditStatus.pending => scheme.error,
      CreditStatus.partial => scheme.tertiary,
      CreditStatus.paid => context.appColors.income,
    };
  }

  void _showPaymentDialog(BuildContext context, FinanceTransaction credit) {
    showDialog<void>(
      context: context,
      builder: (context) => CreditPaymentDialog(transaction: credit),
    );
  }
}

class _CreditSummaryCard extends StatelessWidget {
  const _CreditSummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.tone,
  });

  final String label;
  final int amount;
  final IconData icon;
  final _CreditSummaryTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (background, foreground) = switch (tone) {
      _CreditSummaryTone.info => (colors.infoSurface, colors.info),
      _CreditSummaryTone.paid => (colors.incomeSurface, colors.income),
      _CreditSummaryTone.remaining => (colors.expenseSurface, colors.expense),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(amount),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _CreditSummaryTone { info, paid, remaining }

class _CreditAmount extends StatelessWidget {
  const _CreditAmount({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  final String label;
  final int amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 3),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            CurrencyFormatter.format(amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: emphasized ? colors.expense : null,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreditStatusBadge extends StatelessWidget {
  const _CreditStatusBadge({required this.status, required this.color});

  final CreditStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
