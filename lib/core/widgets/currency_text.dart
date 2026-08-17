import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/transactions/domain/finance_transaction.dart';
import '../formatters/currency_formatter.dart';

class CurrencyText extends StatelessWidget {
  const CurrencyText({
    required this.amount,
    this.type,
    this.showSign = false,
    this.style,
    this.maxLines = 1,
    super.key,
  });

  final int amount;
  final TransactionType? type;
  final bool showSign;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      TransactionType.income => context.appColors.income,
      TransactionType.expense => context.appColors.expense,
      null => null,
    };
    final prefix = showSign && type != null ? '${type!.signedPrefix} ' : '';
    return Text(
      '$prefix${CurrencyFormatter.format(amount)}',
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
