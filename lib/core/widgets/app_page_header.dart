import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520 && trailing != null;
        final titleSection = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.infoSurface,
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: leading ?? Icon(_iconForTitle(title), color: colors.info),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (compact) {
          return _surface(
            colors,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleSection,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerRight, child: trailing!),
              ],
            ),
          );
        }

        return _surface(
          colors,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleSection),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        );
      },
    );
  }

  Widget _surface(AppColors colors, Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Color.lerp(colors.card, colors.infoSurface, .22),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: colors.border.withValues(alpha: .8)),
    ),
    child: child,
  );

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
