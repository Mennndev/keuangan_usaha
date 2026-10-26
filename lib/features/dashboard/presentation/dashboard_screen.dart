import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/finance_chart.dart';
import '../../../core/widgets/finance_summary_card.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/transaction_list_item.dart';
import '../../transactions/domain/finance_summary.dart';
import '../../transactions/domain/finance_transaction.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  PeriodRange _lastTwelveMonths() {
    final now = DateTime.now();
    return PeriodRange(
      start: DateTime(now.year, now.month - 11),
      end: DateTime(now.year, now.month + 1),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = _lastTwelveMonths();
    final totals = ref.watch(allTimeFinanceTotalsProvider);
    final latest = ref.watch(latestTransactionsProvider(5));
    final points = ref.watch(
      cashFlowProvider(CashFlowRequest(range: range, groupByMonth: true)),
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(child: AppPageHeader(title: 'Beranda')),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          sliver: SliverToBoxAdapter(
            child: totals.when(
              loading: () => const _DashboardLoading(),
              error: (error, stackTrace) => ErrorState(
                message: 'Ringkasan keuangan belum dapat dihitung.',
                onRetry: () => ref.invalidate(allTimeFinanceTotalsProvider),
              ),
              data: (summary) => latest.when(
                loading: () => const _DashboardLoading(),
                error: (error, stackTrace) => ErrorState(
                  message: 'Transaksi terbaru belum dapat dimuat.',
                  onRetry: () => ref.invalidate(latestTransactionsProvider(5)),
                ),
                data: (transactions) {
                  if (transactions.isEmpty &&
                      summary.income == 0 &&
                      summary.expense == 0) {
                    return _FirstTransactionState(
                      onAdd: (type) => context.go(
                        '/transactions/new?type=${type.databaseValue}',
                      ),
                    );
                  }
                  return _DashboardContent(
                    summary: summary,
                    transactions: transactions,
                    points: points,
                    onRetryPoints: () => ref.invalidate(
                      cashFlowProvider(
                        CashFlowRequest(range: range, groupByMonth: true),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.summary,
    required this.transactions,
    required this.points,
    required this.onRetryPoints,
  });

  final FinanceSummary summary;
  final List<FinanceTransaction> transactions;
  final AsyncValue<List<CashFlowPoint>> points;
  final VoidCallback onRetryPoints;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = switch (AppBreakpoints.ofWidth(
                  constraints.maxWidth,
                )) {
                  WindowSizeClass.compact => 1,
                  WindowSizeClass.medium => 2,
                  WindowSizeClass.expanded => 3,
                };
                final width =
                    (constraints.maxWidth - ((columns - 1) * 12)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: FinanceSummaryCard(
                        label: 'Total pemasukan',
                        amount: summary.income,
                        tone: SummaryTone.income,
                        icon: Icons.trending_up,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FinanceSummaryCard(
                        label: 'Total pengeluaran',
                        amount: summary.expense,
                        tone: SummaryTone.expense,
                        icon: Icons.trending_down,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FinanceSummaryCard(
                        label: 'Selisih bersih kumulatif',
                        amount: summary.balance,
                        tone: SummaryTone.info,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Arus kas 12 bulan terakhir',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const _MetaPill(label: 'Per bulan'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    points.when(
                      loading: () => const SizedBox(
                        height: 220,
                        child: AppLoadingState(
                          compact: true,
                          message: 'Menyiapkan grafik…',
                        ),
                      ),
                      error: (error, stackTrace) => ErrorState(
                        message: 'Grafik arus kas belum dapat dimuat.',
                        compact: true,
                        onRetry: onRetryPoints,
                      ),
                      data: (data) => FinanceChart(points: data),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    AppBreakpoints.ofWidth(constraints.maxWidth) ==
                    WindowSizeClass.compact;
                final colors = context.appColors;
                final income = FilledButton.icon(
                  onPressed: () => context.go('/transactions/new?type=income'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.income,
                    foregroundColor: _foregroundFor(colors.income),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah pemasukan'),
                );
                final expense = FilledButton.icon(
                  onPressed: () => context.go('/transactions/new?type=expense'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.expense,
                    foregroundColor: _foregroundFor(colors.expense),
                  ),
                  icon: const Icon(Icons.remove),
                  label: const Text('Tambah pengeluaran'),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [income, const SizedBox(height: 10), expense],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: income),
                    const SizedBox(width: 12),
                    Expanded(child: expense),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Transaksi terbaru',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/transactions'),
                  child: const Text('Lihat semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (transactions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.appColors.infoSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 20,
                          color: context.appColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Belum ada transaksi.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: context.appColors.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (
                      var index = 0;
                      index < transactions.length;
                      index++
                    ) ...[
                      TransactionListItem(
                        transaction: transactions[index],
                        showCard: false,
                        onTap: () => context.go(
                          '/transactions/${transactions[index].id}',
                        ),
                      ),
                      if (index < transactions.length - 1)
                        Divider(
                          height: 1,
                          indent: 70,
                          endIndent: 16,
                          color: context.appColors.border,
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.infoSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.info,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

Color _foregroundFor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : Colors.black;
}

class _FirstTransactionState extends StatelessWidget {
  const _FirstTransactionState({required this.onAdd});

  final ValueChanged<TransactionType> onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Mulai catat keuangan usaha',
      message:
          'Database masih kosong. Catat transaksi pertama untuk melihat saldo, arus kas, dan laporan.',
      primaryAction: FilledButton.icon(
        onPressed: () => context.go('/transactions/new'),
        icon: const Icon(Icons.add),
        label: const Text('Catat transaksi pertama'),
      ),
      secondaryAction: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => onAdd(TransactionType.income),
            icon: const Icon(Icons.south_west_rounded),
            label: const Text('Tambah pemasukan'),
          ),
          OutlinedButton.icon(
            onPressed: () => onAdd(TransactionType.expense),
            icon: const Icon(Icons.north_east_rounded),
            label: const Text('Tambah pengeluaran'),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const AppLoadingState(message: 'Menghitung ringkasan keuangan…');
  }
}
