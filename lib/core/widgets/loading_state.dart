import 'package:flutter/material.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({this.message, this.compact = false, super.key});

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox.square(
      dimension: compact ? 24 : 32,
      child: const CircularProgressIndicator(strokeWidth: 3),
    );
    return Semantics(
      liveRegion: true,
      label: message ?? 'Memuat data',
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 28),
          child: message == null
              ? indicator
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    indicator,
                    const SizedBox(width: 14),
                    Flexible(
                      child: Text(
                        message!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
