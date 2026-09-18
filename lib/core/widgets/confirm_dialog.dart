import 'package:flutter/material.dart';

/// Color sólido para el botón destructivo — el token `error`/`AppColors.peligro`
/// del sistema de diseño es un rosa pálido pensado para texto legible sobre
/// fondo oscuro, no para rellenar un botón (se ve lavado). Este sí funciona
/// como relleno.
const _rojoDestructivo = Color(0xFFE0453A);

Future<bool> confirmarDialogo(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoConfirmar = 'Confirmar',
  String textoCancelar = 'Cancelar',
  bool destructivo = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final colorAccion = destructivo ? _rojoDestructivo : scheme.primary;
  final resultado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorAccion.withValues(alpha: 0.16),
            child: Icon(
              destructivo ? Icons.warning_amber_rounded : Icons.help_outline,
              color: colorAccion,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(titulo)),
        ],
      ),
      content: Text(mensaje),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(textoCancelar),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: colorAccion),
                child: Text(textoConfirmar),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return resultado ?? false;
}

/// Snackbar de error homogéneo, listo para pasarle un `ApiException.mensaje`.
void mostrarError(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Theme.of(context).colorScheme.error));
}

void mostrarMensaje(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensaje)));
}
