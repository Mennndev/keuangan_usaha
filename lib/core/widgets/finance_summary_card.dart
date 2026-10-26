import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/transactions/domain/finance_transaction.dart';
import '../formatters/currency_formatter.dart';
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
    final theme = Theme.of(context);
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
    final cardIcon =
        icon ??
        switch (tone) {
          SummaryTone.income => Icons.trending_up_rounded,
          SummaryTone.expense => Icons.trending_down_rounded,
          SummaryTone.info => Icons.account_balance_wallet_rounded,
        };

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$label, ${CurrencyFormatter.format(amount)}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(cardIcon, size: 19, color: foreground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: CurrencyText(
                amount: amount,
                type: type,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 34,
              height: 3,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
