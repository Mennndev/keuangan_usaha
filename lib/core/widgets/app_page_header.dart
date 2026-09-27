import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    required this.title,
    this.leading,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520 && trailing != null;
        final titleSection = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.infoSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: leading ?? Icon(_iconForTitle(title), color: colors.info),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleSection,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: trailing!),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleSection),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        );
      },
    );
  }

  IconData _iconForTitle(String title) {
    final value = title.toLowerCase();
    if (value.contains('beranda')) return Icons.home_rounded;
    if (value.contains('laporan')) return Icons.bar_chart_rounded;
    if (value.contains('kredit')) return Icons.credit_card_rounded;
    if (value.contains('produk') || value.contains('stok')) {
      return Icons.inventory_2_rounded;
    }
    if (value.contains('pelanggan')) return Icons.groups_rounded;
    if (value.contains('pengaturan')) return Icons.tune_rounded;
    return Icons.receipt_long_rounded;
  }
}
