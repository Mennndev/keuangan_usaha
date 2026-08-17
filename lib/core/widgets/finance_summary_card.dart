import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/transactions/domain/finance_transaction.dart';
import 'currency_text.dart';

enum SummaryTone { income, expense, info }

class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({
    required this.label,
    required this.amount,
    required this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final int amount;
  final SummaryTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (surface, foreground, type) = switch (tone) {
      SummaryTone.income => (
        colors.incomeSurface,
        colors.income,
        TransactionType.income,
      ),
      SummaryTone.expense => (
        colors.expenseSurface,
        colors.expense,
        TransactionType.expense,
      ),
      SummaryTone.info => (colors.infoSurface, colors.info, null),
    };
    return Semantics(
      container: true,
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 8),
                ],
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
            CurrencyText(
              amount: amount,
              type: type,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
