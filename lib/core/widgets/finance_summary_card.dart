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
    final cardIcon =
        icon ??
        switch (tone) {
          SummaryTone.income => Icons.trending_up_rounded,
          SummaryTone.expense => Icons.trending_down_rounded,
          SummaryTone.info => Icons.account_balance_wallet_rounded,
        };
    return Semantics(
      container: true,
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Color.lerp(colors.card, surface, .72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: foreground.withValues(alpha: .13)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Icon(cardIcon, size: 18, color: foreground),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: CurrencyText(
                amount: amount,
                type: type,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
