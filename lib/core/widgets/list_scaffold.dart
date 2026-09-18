import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'async_value_view.dart';
import 'fade_slide_in.dart';
import 'icon_avatar.dart';
import 'pressable_scale.dart';
import 'surface_card.dart';

/// Scaffold estándar para las pantallas "listar → crear" de las Fases 3/4
/// del backend (horarios, fotos, productos, recursos, turnos, turno-fechas,
/// excepciones, habilidades...). Solo pide el AsyncValue de la lista y cómo
/// pintar cada fila; el loading/error/vacío/FAB salen gratis.
class ListScaffold<T> extends StatelessWidget {
  final String titulo;
  final AsyncValue<List<T>> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback? onCrear;
  final VoidCallback onRetry;
  final String mensajeVacio;
  final IconData iconoVacio;
  final List<Widget>? acciones;

  /// Etiqueta del contador sobre la lista (ej. "servicios configurados"). Si
  /// se omite, no se muestra el encabezado con el conteo.
  final String? etiquetaContador;

  const ListScaffold({
    super.key,
    required this.titulo,
    required this.items,
    required this.itemBuilder,
    required this.onRetry,
    this.onCrear,
    this.mensajeVacio = 'Todavía no hay nada aquí.',
    this.iconoVacio = Icons.inbox_outlined,
    this.acciones,
    this.etiquetaContador,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo), actions: acciones),
      body: RefreshIndicator(
        onRefresh: () async => onRetry(),
        child: AsyncValueView<List<T>>(
          value: items,
          onRetry: onRetry,
          estaVacio: (data) => data.isEmpty,
          mensajeVacio: mensajeVacio,
          iconoVacio: iconoVacio,
          builder: (context, data) => ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: data.length + (etiquetaContador != null ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (etiquetaContador != null) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text('${data.length} $etiquetaContador', style: Theme.of(context).textTheme.labelMedium),
                      ],
                    ),
                  );
                }
                return FadeSlideIn(indice: index - 1, child: itemBuilder(context, data[index - 1]));
              }
              return FadeSlideIn(indice: index, child: itemBuilder(context, data[index]));
            },
          ),
        ),
      ),
      floatingActionButton: onCrear == null
          ? null
          : FloatingActionButton.extended(
              onPressed: onCrear,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
    );
  }
}

/// Fila estándar de una lista administrable: ícono, título, subtítulo
/// opcional, etiquetas opcionales (solo datos reales del ítem — nunca
/// texto decorativo inventado), editar y eliminar. Usada por casi todos
/// los CRUD simples de Staffing y Directory. `onEliminar` se auto-gestiona:
/// muestra su propio spinner mientras la baja está en curso.
class CrudTile extends StatefulWidget {
  final String titulo;
  final String? subtitulo;
  final IconData icono;
  final Color? colorIcono;
  final List<Widget>? etiquetas;
  final VoidCallback? onEditar;
  final Future<void> Function()? onEliminar;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CrudTile({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.icono = Icons.circle_outlined,
    this.colorIcono,
    this.etiquetas,
    this.onEditar,
    this.onEliminar,
    this.onTap,
    this.trailing,
  });

  @override
  State<CrudTile> createState() => _CrudTileState();
}

class _CrudTileState extends State<CrudTile> {
  bool _eliminando = false;

  Future<void> _eliminar() async {
    setState(() => _eliminando = true);
    await widget.onEliminar!();
    if (mounted) setState(() => _eliminando = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: SurfaceCard(
        margin: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconAvatar(icono: widget.icono, color: widget.colorIcono ?? scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.titulo, style: Theme.of(context).textTheme.titleSmall),
                  if (widget.subtitulo != null)
                    Text(
                      widget.subtitulo!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  if (widget.etiquetas != null && widget.etiquetas!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: widget.etiquetas!),
                  ],
                ],
              ),
            ),
            widget.trailing ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onEditar != null)
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: widget.onEditar),
                    if (widget.onEliminar != null)
                      _eliminando
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : IconButton(icon: const Icon(Icons.delete_outline), onPressed: _eliminar),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
