import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/transactions/domain/finance_summary.dart';
import '../formatters/currency_formatter.dart';

class FinanceChart extends StatelessWidget {
  const FinanceChart({required this.points, this.height = 220, super.key});

  final List<CashFlowPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.infoSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 24,
                  color: colors.info,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada data untuk grafik',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Grafik akan tampil setelah ada transaksi pada periode ini.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final maxValue = points.fold<int>(0, (current, point) {
      final pointMax = point.income > point.expense
          ? point.income
          : point.expense;
      return pointMax > current ? pointMax : current;
    });
    final maxY = maxValue == 0 ? 1.0 : maxValue * 1.2;

    return Semantics(
      label: 'Grafik pemasukan dan pengeluaran, ${points.length} periode',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rawLabels = (constraints.maxWidth / 56).floor();
          final maxLabels = rawLabels < 1
              ? 1
              : rawLabels > points.length
              ? points.length
              : rawLabels;
          final labelStep = (points.length / maxLabels).ceil();
          final barWidth = points.length > 12
              ? 6.0
              : (constraints.maxWidth < 420 ? 8.0 : 10.0);

          return Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Legend(
                    color: colors.income,
                    surface: colors.incomeSurface,
                    label: 'Pemasukan',
                  ),
                  _Legend(
                    color: colors.expense,
                    surface: colors.expenseSurface,
                    label: 'Pengeluaran',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: height,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(10),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        getTooltipColor: (_) => colors.textPrimary,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final point = points[group.x];
                          final label = rodIndex == 0
                              ? 'Pemasukan'
                              : 'Pengeluaran';
                          final amount = rodIndex == 0
                              ? point.income
                              : point.expense;
                          return BarTooltipItem(
                            '$label\n${CurrencyFormatter.format(amount)}',
                            Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: colors.card,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: colors.border.withValues(alpha: .7),
                        strokeWidth: 1,
                        dashArray: const [4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 ||
                                index >= points.length ||
                                index % labelStep != 0) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _shortLabel(points[index].label),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: colors.textSecondary),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < points.length; i++)
                        BarChartGroupData(
                          x: i,
                          barsSpace: 3,
                          barRods: [
                            _rod(
                              value: points[i].income.toDouble(),
                              color: colors.income,
                              trackColor: colors.border,
                              maxY: maxY,
                              width: barWidth,
                            ),
                            _rod(
                              value: points[i].expense.toDouble(),
                              color: colors.expense,
                              trackColor: colors.border,
                              maxY: maxY,
                              width: barWidth,
                            ),
                          ],
                        ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 350),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  BarChartRodData _rod({
    required double value,
    required Color color,
    required Color trackColor,
    required double maxY,
    required double width,
  }) {
    return BarChartRodData(
      toY: value,
      color: color,
      width: width,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: maxY,
        color: trackColor.withValues(alpha: .55),
      ),
    );
  }
}

String _shortLabel(String label) {
  final parts = label.split('-');
  if (parts.length == 3) return parts.last;
  if (parts.length == 2) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final month = int.tryParse(parts.last);
    if (month != null && month >= 1 && month <= 12) return months[month - 1];
  }
  return label;
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.surface,
    required this.label,
  });

  final Color color;
  final Color surface;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
