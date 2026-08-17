import 'package:flutter/material.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.canGoNext = true,
    super.key,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          onPressed: onPrevious,
          tooltip: 'Periode sebelumnya',
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton.outlined(
          onPressed: canGoNext ? onNext : null,
          tooltip: 'Periode berikutnya',
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
