import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/finance_chart.dart';
import '../../../core/widgets/finance_summary_card.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/period_selector.dart';
import '../../../core/widgets/transaction_list_item.dart';
import '../../transactions/domain/finance_summary.dart';
import '../../transactions/domain/finance_transaction.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';

/// Skala spasi 4pt yang dipakai konsisten di seluruh layar laporan.
class _Space {
  const _Space._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _yearly = false;
  TransactionType _categoryType = TransactionType.expense;
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

  String get _periodLabel => _yearly
      ? AppDateFormatter.year(_anchor)
      : AppDateFormatter.monthYear(_anchor);

  String get _periodCaption {
    final lastDay = _range.end.subtract(const Duration(days: 1));
    return '${AppDateFormatter.short(_range.start)} – '
        '${AppDateFormatter.short(lastDay)}';
  }

  String get _summaryCaption => _yearly
      ? 'Akumulasi Januari–Desember ${_anchor.year}'
      : 'Akumulasi ${AppDateFormatter.monthYear(_anchor)}';

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
    final previousRange = _yearly
        ? PeriodRange(
            start: DateTime(_anchor.year - 1),
            end: DateTime(_anchor.year),
          )
        : PeriodRange(
            start: DateTime(_anchor.year, _anchor.month - 1),
            end: DateTime(_anchor.year, _anchor.month),
          );
    final totals = ref.watch(financeTotalsProvider(range));
    final previousTotals = ref.watch(financeTotalsProvider(previousRange));
    final categoryRequest = CategoryReportRequest(
      range: range,
      type: _categoryType,
    );
    final categoryTotals = ref.watch(categoryTotalsProvider(categoryRequest));
    final cashFlowRequest = CashFlowRequest(
      range: range,
      groupByMonth: _yearly,
    );
    final points = ref.watch(cashFlowProvider(cashFlowRequest));
    final transactionFilter = TransactionFilter(
      start: range.start,
      end: range.end,
      limit: 1000,
    );
    final transactions = ref.watch(transactionsProvider(transactionFilter));
    final compact = AppBreakpoints.of(context) == WindowSizeClass.compact;
    final gutter = compact ? _Space.lg : _Space.xl;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, _Space.xxl, gutter, _Space.md),
          sliver: const SliverToBoxAdapter(
            child: AppPageHeader(title: 'Laporan'),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            _Space.sm,
            gutter,
            _Space.xxl + _Space.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PeriodToolbar(
                      yearly: _yearly,
                      label: _periodLabel,
                      caption: _periodCaption,
                      canGoNext: _canGoNext,
                      onYearlyChanged: (yearly) => setState(() {
                        _yearly = yearly;
                        _anchor = DateTime.now();
                      }),
                      onPrevious: () => _move(-1),
                      onNext: () => _move(1),
                    ),
                    const SizedBox(height: _Space.xxl),
                    _SectionHeading(
                      title: 'Ringkasan periode',
                      description: _summaryCaption,
                    ),
                    const SizedBox(height: _Space.md),
                    totals.when(
                      loading: () => const _ReportLoading(
                        message: 'Menghitung laporan…',
                        height: 180,
                      ),
                      error: (error, stackTrace) => ErrorState(
                        message: 'Ringkasan periode belum dapat dihitung.',
                        onRetry: () =>
                            ref.invalidate(financeTotalsProvider(range)),
                      ),
                      data: (summary) => Column(
                        children: [
                          _SummaryGrid(summary: summary),
                          const SizedBox(height: _Space.md),
                          _PeriodComparison(
                            current: summary,
                            previous: previousTotals,
                            previousLabel: _yearly
                                ? 'tahun sebelumnya'
                                : 'bulan sebelumnya',
                            onRetry: () => ref.invalidate(
                              financeTotalsProvider(previousRange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: _Space.xxl),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final expanded =
                            AppBreakpoints.ofWidth(constraints.maxWidth) ==
                            WindowSizeClass.expanded;
                        final chart = _ChartCard(
                          yearly: _yearly,
                          points: points,
                          onRetry: () =>
                              ref.invalidate(cashFlowProvider(cashFlowRequest)),
                        );
                        final periodSummary = _PeriodSummaryCard(
                          totals: totals,
                          periodLabel: _periodLabel,
                          onRetry: () =>
                              ref.invalidate(financeTotalsProvider(range)),
                        );
                        if (!expanded) {
                          return Column(
                            children: [
                              chart,
                              const SizedBox(height: _Space.lg),
                              periodSummary,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: chart),
                            const SizedBox(width: _Space.lg),
                            Expanded(child: periodSummary),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: _Space.xxl),
                    _CategoryBreakdown(
                      type: _categoryType,
                      totals: categoryTotals,
                      onTypeChanged: (type) =>
                          setState(() => _categoryType = type),
                      onRetry: () => ref.invalidate(
                        categoryTotalsProvider(categoryRequest),
                      ),
                    ),
                    const SizedBox(height: _Space.xxl),
                    _TransactionsSection(
                      transactions: transactions,
                      onAdd: () => context.go('/transactions/new'),
                      onRetry: () => ref.invalidate(
                        transactionsProvider(transactionFilter),
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
}

class _PeriodToolbar extends StatelessWidget {
  const _PeriodToolbar({
    required this.yearly,
    required this.label,
    required this.caption,
    required this.canGoNext,
    required this.onYearlyChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final bool yearly;
  final String label;
  final String caption;
  final bool canGoNext;
  final ValueChanged<bool> onYearlyChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            AppBreakpoints.ofWidth(constraints.maxWidth) ==
            WindowSizeClass.compact;
        final heading = Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.infoSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.event_note_rounded,
                size: 19,
                color: colors.info,
              ),
            ),
            const SizedBox(width: _Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Periode laporan', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 1),
                  Text(
                    compact
                        ? 'Pilih rentang waktu laporan'
                        : 'Pilih rentang waktu yang ingin dianalisis',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final toggle = _PeriodModeToggle(
          yearly: yearly,
          onChanged: onYearlyChanged,
        );
        final selector = PeriodSelector(
          label: label,
          caption: caption,
          onPrevious: onPrevious,
          onNext: onNext,
          canGoNext: canGoNext,
        );

        return Card(
          child: Padding(
            padding: EdgeInsets.all(compact ? _Space.lg : _Space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact) ...[
                  heading,
                  const SizedBox(height: _Space.md),
                  toggle,
                ] else
                  Row(
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: _Space.lg),
                      toggle,
                    ],
                  ),
                const SizedBox(height: _Space.lg),
                selector,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PeriodModeToggle extends StatelessWidget {
  const _PeriodModeToggle({required this.yearly, required this.onChanged});

  final bool yearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.calendar_view_month_rounded, size: 18),
          label: Text('Bulanan'),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.calendar_today_rounded, size: 18),
          label: Text('Tahunan'),
        ),
      ],
      selected: {yearly},
      onSelectionChanged: (selection) => onChanged(selection.single),
      style: _segmentedStyle(context),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.description, this.trailing});

  final String title;
  final String? description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (description != null) ...[
          const SizedBox(height: 2),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
    if (trailing == null) return heading;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              const SizedBox(height: _Space.sm),
              trailing!,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: _Space.md),
            trailing!,
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.yearly,
    required this.points,
    required this.onRetry,
  });

  final bool yearly;
  final AsyncValue<List<CashFlowPoint>> points;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Arus kas', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Pemasukan vs pengeluaran',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _Space.md),
                _MetaPill(label: yearly ? 'Per bulan' : 'Per hari'),
              ],
            ),
            const SizedBox(height: _Space.xl),
            points.when(
              loading: () => const SizedBox(
                height: 260,
                child: AppLoadingState(
                  compact: true,
                  message: 'Menyiapkan grafik…',
                ),
              ),
              error: (error, stackTrace) => ErrorState(
                message: 'Grafik periode belum dapat dimuat.',
                compact: true,
                onRetry: onRetry,
              ),
              data: (data) {
                if (data.isEmpty) {
                  return const EmptyState(
                    icon: Icons.insights_rounded,
                    title: 'Belum ada data grafik',
                    message:
                        'Grafik pemasukan dan pengeluaran akan muncul setelah ada transaksi pada periode ini.',
                  );
                }
                return FinanceChart(points: data, height: 240);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSummaryCard extends StatelessWidget {
  const _PeriodSummaryCard({
    required this.totals,
    required this.periodLabel,
    required this.onRetry,
  });

  final AsyncValue<FinanceSummary> totals;
  final String periodLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.infoSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.summarize_rounded,
                    size: 19,
                    color: colors.info,
                  ),
                ),
                const SizedBox(width: _Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan periode',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        periodLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: _Space.xl),
            totals.when(
              loading: () => const SizedBox(
                height: 180,
                child: AppLoadingState(
                  compact: true,
                  message: 'Memuat ringkasan…',
                ),
              ),
              error: (error, stackTrace) => ErrorState(
                message: 'Ringkasan belum tersedia.',
                compact: true,
                onRetry: onRetry,
              ),
              data: (summary) => Column(
                children: [
                  _SummaryRow(
                    icon: Icons.south_west_rounded,
                    label: 'Pemasukan',
                    amount: summary.income,
                    tone: colors.income,
                    surface: colors.incomeSurface,
                  ),
                  Divider(height: _Space.xxl, color: colors.border),
                  _SummaryRow(
                    icon: Icons.north_east_rounded,
                    label: 'Pengeluaran',
                    amount: summary.expense,
                    tone: colors.expense,
                    surface: colors.expenseSurface,
                  ),
                  const SizedBox(height: _Space.sm),
                  _SummaryRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Saldo akhir',
                    amount: summary.balance,
                    tone: colors.info,
                    surface: colors.infoSurface,
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.tone,
    required this.surface,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final int amount;
  final Color tone;
  final Color surface;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: emphasize ? _Space.md : 0,
        vertical: emphasize ? _Space.md : _Space.xs,
      ),
      decoration: emphasize
          ? BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tone.withValues(alpha: .18)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: emphasize ? colors.card : surface,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: tone),
          ),
          const SizedBox(width: _Space.md),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: emphasize ? colors.textPrimary : colors.textSecondary,
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: _Space.md),
          Flexible(
            child: Text(
              CurrencyFormatter.format(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style:
                  (emphasize
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleSmall)
                      ?.copyWith(
                        color: emphasize ? colors.textPrimary : tone,
                        fontWeight: FontWeight.w700,
                      ),
            ),
          ),
        ],
      ),
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
        final columns = switch (AppBreakpoints.ofWidth(constraints.maxWidth)) {
          WindowSizeClass.compact => 1,
          WindowSizeClass.medium => 3,
          WindowSizeClass.expanded => 3,
        };
        final width =
            (constraints.maxWidth - ((columns - 1) * _Space.md)) / columns;
        return Wrap(
          spacing: _Space.md,
          runSpacing: _Space.md,
          children: [
            SizedBox(
              width: width,
              child: FinanceSummaryCard(
                label: 'Total pemasukan',
                amount: summary.income,
                tone: SummaryTone.income,
                icon: Icons.south_west_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: FinanceSummaryCard(
                label: 'Total pengeluaran',
                amount: summary.expense,
                tone: SummaryTone.expense,
                icon: Icons.north_east_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: FinanceSummaryCard(
                label: 'Saldo akhir',
                amount: summary.balance,
                tone: SummaryTone.info,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PeriodComparison extends StatelessWidget {
  const _PeriodComparison({
    required this.current,
    required this.previous,
    required this.previousLabel,
    required this.onRetry,
  });

  final FinanceSummary current;
  final AsyncValue<FinanceSummary> previous;
  final String previousLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_Space.xl),
        child: previous.when(
          loading: () => const SizedBox(
            height: 140,
            child: AppLoadingState(
              compact: true,
              message: 'Memuat perbandingan…',
            ),
          ),
          error: (error, stack) => ErrorState(
            compact: true,
            message: 'Perbandingan periode sebelumnya belum tersedia.',
            onRetry: onRetry,
          ),
          data: (prior) {
            final incomeDelta = current.income - prior.income;
            final expenseDelta = current.expense - prior.expense;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.infoSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        size: 19,
                        color: colors.info,
                      ),
                    ),
                    const SizedBox(width: _Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dibanding $previousLabel',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Perubahan dibanding periode pembanding',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _Space.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        AppBreakpoints.ofWidth(constraints.maxWidth) ==
                        WindowSizeClass.compact;
                    final incomeTile = _ComparisonTile(
                      label: 'Pemasukan',
                      current: current.income,
                      previous: prior.income,
                      delta: incomeDelta,
                      positiveIsGood: true,
                    );
                    final expenseTile = _ComparisonTile(
                      label: 'Pengeluaran',
                      current: current.expense,
                      previous: prior.expense,
                      delta: expenseDelta,
                      positiveIsGood: false,
                    );
                    if (compact) {
                      return Column(
                        children: [
                          incomeTile,
                          const SizedBox(height: _Space.md),
                          expenseTile,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: incomeTile),
                        const SizedBox(width: _Space.md),
                        Expanded(child: expenseTile),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ComparisonTile extends StatelessWidget {
  const _ComparisonTile({
    required this.label,
    required this.current,
    required this.previous,
    required this.delta,
    required this.positiveIsGood,
  });

  final String label;
  final int current;
  final int previous;
  final int delta;
  final bool positiveIsGood;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final flat = delta == 0;
    final isUp = delta > 0;
    final Color tone;
    final Color surface;
    if (flat) {
      tone = colors.textSecondary;
      surface = colors.canvas;
    } else if (isUp == positiveIsGood) {
      tone = colors.income;
      surface = colors.incomeSurface;
    } else {
      tone = colors.expense;
      surface = colors.expenseSurface;
    }
    final deltaLabel = flat
        ? 'Sama dengan periode sebelumnya'
        : '${isUp ? 'Naik' : 'Turun'} ${CurrencyFormatter.format(delta.abs())}';

    return Container(
      padding: const EdgeInsets.all(_Space.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colors.card.withValues(alpha: .85),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  flat
                      ? Icons.remove_rounded
                      : isUp
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16,
                  color: tone,
                ),
              ),
            ],
          ),
          const SizedBox(height: _Space.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(current),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: _Space.xs),
          Row(
            children: [
              Icon(
                flat
                    ? Icons.horizontal_rule_rounded
                    : isUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: tone,
              ),
              const SizedBox(width: _Space.xs),
              Flexible(
                child: Text(
                  deltaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Sebelumnya ${CurrencyFormatter.format(previous)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.type,
    required this.totals,
    required this.onTypeChanged,
    required this.onRetry,
  });

  final TransactionType type;
  final AsyncValue<List<CategoryFinanceSummary>> totals;
  final ValueChanged<TransactionType> onTypeChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final isExpense = type == TransactionType.expense;
    final tone = isExpense ? colors.expense : colors.income;
    final surface = isExpense ? colors.expenseSurface : colors.incomeSurface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(_Space.xl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                AppBreakpoints.ofWidth(constraints.maxWidth) ==
                WindowSizeClass.compact;
            final heading = Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.donut_small_rounded, size: 19, color: tone),
                ),
                const SizedBox(width: _Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rincian per kategori',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isExpense
                            ? 'Distribusi pengeluaran pada periode ini'
                            : 'Distribusi pemasukan pada periode ini',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final toggle = SegmentedButton<TransactionType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  icon: Icon(Icons.north_east_rounded, size: 16),
                  label: Text('Pengeluaran'),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  icon: Icon(Icons.south_west_rounded, size: 16),
                  label: Text('Pemasukan'),
                ),
              ],
              selected: {type},
              onSelectionChanged: (selection) =>
                  onTypeChanged(selection.single),
              style: _segmentedStyle(context),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact) ...[
                  heading,
                  const SizedBox(height: _Space.md),
                  toggle,
                ] else
                  Row(
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: _Space.lg),
                      toggle,
                    ],
                  ),
                const SizedBox(height: _Space.lg),
                totals.when(
                  loading: () => const SizedBox(
                    height: 160,
                    child: AppLoadingState(
                      compact: true,
                      message: 'Memuat kategori…',
                    ),
                  ),
                  error: (error, stack) => ErrorState(
                    compact: true,
                    message: 'Rincian kategori belum dapat dimuat.',
                    onRetry: onRetry,
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: _Space.sm,
                        ),
                        child: EmptyState(
                          icon: Icons.pie_chart_outline_rounded,
                          title: 'Belum ada rincian kategori',
                          message: isExpense
                              ? 'Belum ada transaksi pengeluaran pada periode ini.'
                              : 'Belum ada transaksi pemasukan pada periode ini.',
                        ),
                      );
                    }
                    final total = items.fold<int>(
                      0,
                      (sum, item) => sum + item.amount,
                    );
                    return Column(
                      children: [
                        for (var index = 0; index < items.length; index++) ...[
                          if (index > 0)
                            Divider(height: _Space.xxl, color: colors.border),
                          _CategoryRow(
                            item: items[index],
                            total: total,
                            tone: tone,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.item,
    required this.total,
    required this.tone,
  });

  final CategoryFinanceSummary item;
  final int total;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final share = total <= 0
        ? 0.0
        : (item.amount / total).clamp(0.0, 1.0).toDouble();
    return Semantics(
      container: true,
      label:
          '${item.category}, ${CurrencyFormatter.format(item.amount)}, '
          '${_percentLabel(share)}, ${item.transactionCount} transaksi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              ),
              const SizedBox(width: _Space.sm),
              Expanded(
                child: Text(
                  item.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(width: _Space.md),
              Flexible(
                child: Text(
                  CurrencyFormatter.format(item.amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _Space.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 8,
              color: tone,
              backgroundColor: colors.border.withValues(alpha: .45),
            ),
          ),
          const SizedBox(height: _Space.xs),
          Row(
            children: [
              Text(
                '${item.transactionCount} transaksi',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                _percentLabel(share),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({
    required this.transactions,
    required this.onAdd,
    required this.onRetry,
  });

  final AsyncValue<List<FinanceTransaction>> transactions;
  final VoidCallback onAdd;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final items = transactions.asData?.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(
          title: 'Transaksi dalam periode',
          description: 'Ketuk salah satu transaksi untuk melihat detailnya.',
          trailing: items == null || items.isEmpty
              ? null
              : _MetaPill(label: '${items.length} transaksi'),
        ),
        const SizedBox(height: _Space.md),
        transactions.when(
          loading: () => const _ReportLoading(
            message: 'Memuat transaksi periode…',
            height: 180,
          ),
          error: (error, stackTrace) => ErrorState(
            message: 'Daftar transaksi belum dapat dimuat.',
            onRetry: onRetry,
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada transaksi di periode ini',
                message:
                    'Nilai laporan tetap Rp 0. Tambahkan transaksi untuk mulai membentuk grafik.',
                primaryAction: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah transaksi'),
                ),
              );
            }
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    TransactionListItem(
                      transaction: items[index],
                      showCard: false,
                      onTap: () =>
                          context.go('/transactions/${items[index].id}'),
                    ),
                    if (index < items.length - 1)
                      Divider(
                        height: 1,
                        indent: 70,
                        endIndent: _Space.lg,
                        color: context.appColors.border,
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: _Space.md,
        vertical: _Space.xs,
      ),
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

class _ReportLoading extends StatelessWidget {
  const _ReportLoading({required this.message, this.height = 120});

  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AppLoadingState(message: message, compact: true),
    );
  }
}

ButtonStyle _segmentedStyle(BuildContext context) {
  final colors = context.appColors;
  final theme = Theme.of(context);
  return ButtonStyle(
    side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      return states.contains(WidgetState.selected)
          ? colors.infoSurface
          : Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      return states.contains(WidgetState.selected)
          ? colors.info
          : colors.textSecondary;
    }),
    textStyle: WidgetStatePropertyAll(theme.textTheme.labelLarge),
  );
}

String _percentLabel(double share) {
  final percent = share * 100;
  if (percent > 0 && percent < 1) return '<1%';
  return '${percent.round()}%';
}
