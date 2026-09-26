import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.primaryAction,
    this.secondaryAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 22),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .7),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Icon(
                      icon,
                      size: 32,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (primaryAction != null) ...[
                  const SizedBox(height: 24),
                  primaryAction!,
                ],
                if (secondaryAction != null) ...[
                  const SizedBox(height: 12),
                  secondaryAction!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
