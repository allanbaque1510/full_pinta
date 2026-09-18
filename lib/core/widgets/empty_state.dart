import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String mensaje;
  final IconData icono;
  final Widget? accion;

  const EmptyState({
    super.key,
    required this.mensaje,
    this.icono = Icons.inbox_outlined,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if (accion != null) ...[
              const SizedBox(height: 16),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}
