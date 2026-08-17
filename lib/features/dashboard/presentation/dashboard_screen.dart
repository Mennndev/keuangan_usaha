import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/currency_formatter.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/finance_chart.dart';
import '../../../core/widgets/finance_summary_card.dart';
import '../../../core/widgets/transaction_list_item.dart';
import '../../settings/presentation/providers/settings_providers.dart';
import '../../transactions/domain/finance_summary.dart';
import '../../transactions/domain/finance_transaction.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  PeriodRange _currentMonth() {
    final now = DateTime.now();
    return PeriodRange(
      start: DateTime(now.year, now.month),
      end: DateTime(now.year, now.month + 1),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = _currentMonth();
    final totals = ref.watch(financeTotalsProvider(range));
    final latest = ref.watch(latestTransactionsProvider(5));
    final points = ref.watch(
      cashFlowProvider(CashFlowRequest(range: range, groupByMonth: false)),
    );
    final profile = ref.watch(businessProfileProvider).value;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: AppPageHeader(
              title: 'Beranda',
              subtitle:
                  'Ringkasan ${profile?.businessName ?? 'keuangan usaha Anda'}',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          sliver: SliverToBoxAdapter(
            child: totals.when(
              loading: () => const _DashboardLoading(),
              error: (error, stackTrace) => ErrorState(
                message: 'Ringkasan keuangan belum dapat dihitung.',
                onRetry: () => ref.invalidate(financeTotalsProvider(range)),
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
  });

  final FinanceSummary summary;
  final List<FinanceTransaction> transactions;
  final AsyncValue<List<CashFlowPoint>> points;

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
                final columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 520
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - ((columns - 1) * 12)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: width,
                      child: FinanceSummaryCard(
                        label: 'Total pemasukan bulan ini',
                        amount: summary.income,
                        tone: SummaryTone.income,
                        icon: Icons.trending_up,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FinanceSummaryCard(
                        label: 'Total pengeluaran bulan ini',
                        amount: summary.expense,
                        tone: SummaryTone.expense,
                        icon: Icons.trending_down,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: FinanceSummaryCard(
                        label: 'Sisa saldo bulan ini',
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Arus kas bulan ini',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatSigned(
                    summary.balance.abs(),
                    income: summary.balance >= 0,
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: summary.balance >= 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: points.when(
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text('Menyiapkan grafik…'),
                        ],
                      ),
                    ),
                  ),
                  error: (error, stackTrace) => const ErrorState(
                    message: 'Grafik arus kas belum dapat dimuat.',
                    compact: true,
                  ),
                  data: (data) => FinanceChart(points: data),
                ),
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                final income = FilledButton.icon(
                  onPressed: () => context.go('/transactions/new?type=income'),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appColors.income,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah pemasukan'),
                );
                final expense = FilledButton.icon(
                  onPressed: () => context.go('/transactions/new?type=expense'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
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
            const SizedBox(height: 24),
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
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Belum ada transaksi pada periode ini.'),
                ),
              )
            else
              for (var index = 0; index < transactions.length; index++) ...[
                TransactionListItem(
                  transaction: transactions[index],
                  showCard: false,
                  onTap: () =>
                      context.go('/transactions/${transactions[index].id}'),
                ),
                if (index < transactions.length - 1) const Divider(height: 1),
              ],
          ],
        ),
      ),
    );
  }
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Menghitung ringkasan keuangan…'),
          ],
        ),
      ),
    );
  }
}
