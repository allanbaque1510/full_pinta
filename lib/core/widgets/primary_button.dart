import 'package:flutter/material.dart';

/// Botón que muestra su propio spinner mientras `isLoading` es true y se
/// autodeshabilita — evita que un doble-tap dispare la acción dos veces
/// (relevante sobre todo en agendar/cancelar, que además llevan
/// Idempotency-Key, pero es buena práctica en cualquier acción de red).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
              ],
            ),
    );
  }
}
