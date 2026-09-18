import 'package:flutter/material.dart';

import 'icon_avatar.dart';
import 'pressable_scale.dart';
import 'tag_pill.dart';

/// Fila de acceso a una sección: ícono + título (+ subtítulo, + contador
/// opcional) + chevron. Es el mismo patrón en el panel del negocio, el
/// panel de un profesional y el menú de cuenta — antes vivía triplicado
/// como `_MenuItem`/`_Opcion` en cada pantalla.
class MenuAccessTile extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final String? contador;
  final Color? color;
  final VoidCallback onTap;

  const MenuAccessTile({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.contador,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: PressableScale(
          onTap: onTap,
          child: ListTile(
            leading: IconAvatar(icono: icono, color: color ?? scheme.primary),
            title: Text(titulo, style: color != null ? TextStyle(color: color) : null),
            subtitle: subtitulo == null ? null : Text(subtitulo!, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (contador != null) ...[
                  TagPill(texto: contador!, neutro: true),
                  const SizedBox(width: 6),
                ],
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
