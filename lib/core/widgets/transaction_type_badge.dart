import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/transactions/domain/finance_transaction.dart';

class TransactionTypeBadge extends StatelessWidget {
  const TransactionTypeBadge({required this.type, super.key});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final isIncome = type == TransactionType.income;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isIncome
            ? context.appColors.incomeSurface
            : context.appColors.expenseSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 14,
            color: isIncome
                ? context.appColors.income
                : context.appColors.expense,
          ),
          const SizedBox(width: 5),
          Text(
            type.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isIncome
                  ? context.appColors.income
                  : context.appColors.expense,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
