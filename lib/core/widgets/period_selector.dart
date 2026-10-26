import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.caption,
    this.canGoNext = true,
    super.key,
  });

  final String label;

  /// Keterangan rentang tanggal di bawah label, misalnya `1 Okt 2026 – 31 Okt 2026`.
  final String? caption;

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: caption == null ? 'Periode $label' : 'Periode $label, $caption',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            IconButton.outlined(
              onPressed: onPrevious,
              tooltip: 'Periode sebelumnya',
              style: IconButton.styleFrom(
                backgroundColor: colors.card,
                side: BorderSide(color: colors.border),
              ),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        label,
                        key: ValueKey(label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (caption != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            IconButton.outlined(
              onPressed: canGoNext ? onNext : null,
              tooltip: 'Periode berikutnya',
              style: IconButton.styleFrom(
                backgroundColor: colors.card,
                side: BorderSide(color: colors.border),
              ),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
