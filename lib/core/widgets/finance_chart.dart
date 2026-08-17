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
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 36,
                color: context.appColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada data untuk grafik',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textSecondary,
                ),
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
    final labelStep = points.length > 12 ? (points.length / 6).ceil() : 1;

    return Semantics(
      label: 'Grafik pemasukan dan pengeluaran, ${points.length} periode',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: context.appColors.income, label: 'Pemasukan'),
              const SizedBox(width: 20),
              _Legend(color: context.appColors.expense, label: 'Pengeluaran'),
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
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final point = points[group.x];
                      final label = rodIndex == 0 ? 'Pemasukan' : 'Pengeluaran';
                      final amount = rodIndex == 0
                          ? point.income
                          : point.expense;
                      return BarTooltipItem(
                        '$label\n${CurrencyFormatter.format(amount)}',
                        Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: Colors.white,
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
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: context.appColors.border, strokeWidth: 1),
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
                              style: Theme.of(context).textTheme.labelSmall,
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
                        BarChartRodData(
                          toY: points[i].income.toDouble(),
                          color: context.appColors.income,
                          width: points.length > 12 ? 6 : 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: points[i].expense.toDouble(),
                          color: context.appColors.expense,
                          width: points.length > 12 ? 6 : 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 350),
            ),
          ),
        ],
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
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
