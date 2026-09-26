import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    this.onRetry,
    this.compact = false,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: EdgeInsets.all(compact ? 18 : 26),
          decoration: BoxDecoration(
            color: colors.errorContainer.withValues(alpha: .34),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.error.withValues(alpha: .16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 44 : 56,
                height: compact ? 44 : 56,
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.cloud_off_outlined,
                  size: compact ? 24 : 30,
                  color: colors.error,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Data belum dapat dimuat',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
