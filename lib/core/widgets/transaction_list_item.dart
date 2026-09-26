import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/transactions/domain/finance_transaction.dart';
import '../formatters/date_formatter.dart';
import 'currency_text.dart';

enum TransactionMenuAction { edit, delete }

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    required this.transaction,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.showCard = true,
    super.key,
  });

  final FinanceTransaction transaction;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 440;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(
              [
                AppDateFormatter.short(transaction.transactionDate),
                if (transaction.category != null) transaction.category!,
              ].join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        );
        final icon = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isIncome
                ? context.appColors.incomeSurface
                : context.appColors.expenseSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: isIncome
                ? context.appColors.income
                : context.appColors.expense,
            semanticLabel: transaction.type.label,
          ),
        );
        final amount = CurrencyText(
          amount: transaction.amount,
          type: transaction.type,
          showSign: true,
          style: Theme.of(context).textTheme.bodyMedium,
        );
        final actions = _actions(context);

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          icon,
                          const SizedBox(width: 12),
                          Expanded(child: details),
                          if (actions != null) actions,
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(alignment: Alignment.centerRight, child: amount),
                    ],
                  )
                : Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(child: details),
                      const SizedBox(width: 8),
                      Flexible(child: amount),
                      if (actions != null) actions,
                    ],
                  ),
          ),
        );
      },
    );
    if (!showCard) return content;
    return Card(clipBehavior: Clip.antiAlias, child: content);
  }

  Widget? _actions(BuildContext context) {
    if (onEdit == null && onDelete == null) return null;
    return PopupMenuButton<TransactionMenuAction>(
      tooltip: 'Aksi transaksi ${transaction.name}',
      onSelected: (action) {
        switch (action) {
          case TransactionMenuAction.edit:
            onEdit?.call();
            break;
          case TransactionMenuAction.delete:
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: TransactionMenuAction.edit,
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: TransactionMenuAction.delete,
            child: ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Hapus',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}
