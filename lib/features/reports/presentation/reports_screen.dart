import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/finance_chart.dart';
import '../../../core/widgets/finance_summary_card.dart';
import '../../../core/widgets/period_selector.dart';
import '../../../core/widgets/transaction_list_item.dart';
import '../../transactions/domain/finance_summary.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _yearly = false;
  DateTime _anchor = DateTime.now();

  PeriodRange get _range {
    if (_yearly) {
      return PeriodRange(
        start: DateTime(_anchor.year),
        end: DateTime(_anchor.year + 1),
      );
    }
    return PeriodRange(
      start: DateTime(_anchor.year, _anchor.month),
      end: DateTime(_anchor.year, _anchor.month + 1),
    );
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _yearly
        ? _anchor.year < now.year
        : DateTime(
            _anchor.year,
            _anchor.month,
          ).isBefore(DateTime(now.year, now.month));
  }

  void _move(int delta) {
    setState(() {
      _anchor = _yearly
          ? DateTime(_anchor.year + delta)
          : DateTime(_anchor.year, _anchor.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final totals = ref.watch(financeTotalsProvider(range));
    final points = ref.watch(
      cashFlowProvider(CashFlowRequest(range: range, groupByMonth: _yearly)),
    );
    final transactions = ref.watch(
      transactionsProvider(
        TransactionFilter(start: range.start, end: range.end, limit: 1000),
      ),
    );

    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: AppPageHeader(
              title: 'Laporan',
              subtitle: 'Pantau kondisi dan tren keuangan usaha',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.calendar_view_month_outlined),
                          label: Text('Bulanan'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.calendar_today_outlined),
                          label: Text('Tahunan'),
                        ),
                      ],
                      selected: {_yearly},
                      onSelectionChanged: (selection) => setState(() {
                        _yearly = selection.single;
                        _anchor = DateTime.now();
                      }),
                    ),
                    const SizedBox(height: 14),
                    PeriodSelector(
                      label: _yearly
                          ? AppDateFormatter.year(_anchor)
                          : AppDateFormatter.monthYear(_anchor),
                      onPrevious: () => _move(-1),
                      onNext: () => _move(1),
                      canGoNext: _canGoNext,
                    ),
                    const SizedBox(height: 18),
                    totals.when(
                      loading: () =>
                          const _ReportLoading(message: 'Menghitung laporan…'),
                      error: (error, stackTrace) => ErrorState(
                        message: 'Ringkasan periode belum dapat dihitung.',
                        onRetry: () =>
                            ref.invalidate(financeTotalsProvider(range)),
                      ),
                      data: (summary) => _SummaryGrid(summary: summary),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 860;
                        final chart = Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pemasukan vs pengeluaran',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 18),
                                points.when(
                                  loading: () => const _ReportLoading(
                                    message: 'Menyiapkan grafik…',
                                    height: 220,
                                  ),
                                  error: (error, stackTrace) => const ErrorState(
                                    message:
                                        'Grafik periode belum dapat dimuat.',
                                    compact: true,
                                  ),
                                  data: (data) => FinanceChart(points: data),
                                ),
                              ],
                            ),
                          ),
                        );
                        final periodSummary = Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ringkasan periode',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 14),
                                totals.when(
                                  loading: () => const _ReportLoading(
                                    message: 'Memuat ringkasan…',
                                    height: 160,
                                  ),
                                  error: (error, stackTrace) =>
                                      const ErrorState(
                                        message: 'Ringkasan belum tersedia.',
                                        compact: true,
                                      ),
                                  data: (summary) => Column(
                                    children: [
                                      _SummaryRow(
                                        label: 'Pemasukan',
                                        amount: summary.income,
                                      ),
                                      _SummaryRow(
                                        label: 'Pengeluaran',
                                        amount: summary.expense,
                                      ),
                                      _SummaryRow(
                                        label: 'Saldo akhir',
                                        amount: summary.balance,
                                        emphasize: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (!wide) {
                          return Column(
                            children: [
                              chart,
                              const SizedBox(height: 14),
                              periodSummary,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: chart),
                            const SizedBox(width: 14),
                            Expanded(child: periodSummary),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Transaksi dalam periode',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    transactions.when(
                      loading: () => const _ReportLoading(
                        message: 'Memuat transaksi periode…',
                      ),
                      error: (error, stackTrace) => ErrorState(
                        message: 'Daftar transaksi belum dapat dimuat.',
                        onRetry: () => ref.invalidate(
                          transactionsProvider(
                            TransactionFilter(
                              start: range.start,
                              end: range.end,
                              limit: 1000,
                            ),
                          ),
                        ),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return EmptyState(
                            icon: Icons.bar_chart_outlined,
                            title: 'Belum ada transaksi di periode ini',
                            message:
                                'Nilai laporan tetap Rp 0. Tambahkan transaksi untuk mulai membentuk grafik.',
                            primaryAction: FilledButton.icon(
                              onPressed: () => context.go('/transactions/new'),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah transaksi'),
                            ),
                          );
                        }
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < items.length;
                                index++
                              ) ...[
                                TransactionListItem(
                                  transaction: items[index],
                                  showCard: false,
                                  onTap: () => context.go(
                                    '/transactions/${items[index].id}',
                                  ),
                                ),
                                if (index < items.length - 1)
                                  const Divider(height: 1),
                              ],
                            ],
                          ),
                        );
                      },
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
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
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
              ),
            ),
            SizedBox(
              width: width,
              child: FinanceSummaryCard(
                label: 'Total pengeluaran',
                amount: summary.expense,
                tone: SummaryTone.expense,
              ),
            ),
            SizedBox(
              width: width,
              child: FinanceSummaryCard(
                label: 'Saldo akhir',
                amount: summary.balance,
                tone: SummaryTone.info,
              ),
            ),
            SizedBox(
              width: width,
              child: FinanceSummaryCard(
                label: 'Selisih',
                amount: summary.balance,
                tone: summary.balance >= 0
                    ? SummaryTone.income
                    : SummaryTone.expense,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final int amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              CurrencyFormatter.format(amount),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportLoading extends StatelessWidget {
  const _ReportLoading({required this.message, this.height = 120});

  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(message),
          ],
        ),
      ),
    );
  }
}
