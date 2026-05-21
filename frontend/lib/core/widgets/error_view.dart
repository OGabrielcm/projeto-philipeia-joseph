import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, color: AppColors.accent),
                label: const Text('Tentar novamente',
                    style: TextStyle(color: AppColors.accent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent),
                ),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
