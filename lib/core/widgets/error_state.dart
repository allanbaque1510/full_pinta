import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ErrorState extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.mensaje, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.peligro),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
