import 'package:flutter/material.dart';

/// Loading general reutilizable: tapa el contenido con una capa tenue y un
/// spinner mientras `visible` es true, y bloquea los toques para evitar
/// doble acción (cambiar un consentimiento, guardar un perfil, etc.).
///
/// Uso: envuelve el `body` de una pantalla y activa `visible` con el estado
/// local `_guardando` / `_procesando.isNotEmpty`:
///   LoadingOverlay(visible: _guardando, mensaje: 'Guardando...', child: ...)
class LoadingOverlay extends StatelessWidget {
  final bool visible;
  final String? mensaje;
  final Widget child;

  const LoadingOverlay({super.key, required this.visible, required this.child, this.mensaje});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: scheme.scrim.withValues(alpha: 0.28),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: 0.12), blurRadius: 20)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 3)),
                      if (mensaje != null) ...[
                        const SizedBox(height: 12),
                        Text(mensaje!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
