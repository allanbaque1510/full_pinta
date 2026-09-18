import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import 'empty_state.dart';
import 'error_state.dart';

/// Renderiza un `AsyncValue<T>` de Riverpod con el mismo patrón en toda la
/// app: loading / error con reintento / vacío / datos. Evita repetir el
/// switch en cada pantalla que consume un provider async.
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final bool Function(T data)? estaVacio;
  final String mensajeVacio;
  final IconData iconoVacio;

  const AsyncValueView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.estaVacio,
    this.mensajeVacio = 'No hay nada por aquí todavía.',
    this.iconoVacio = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final contenido = value.when(
      data: (data) {
        if (estaVacio != null && estaVacio!(data)) {
          return KeyedSubtree(key: const ValueKey('vacio'), child: EmptyState(mensaje: mensajeVacio, icono: iconoVacio));
        }
        return KeyedSubtree(key: const ValueKey('datos'), child: builder(context, data));
      },
      loading: () => const Center(
        key: ValueKey('cargando'),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => KeyedSubtree(
        key: const ValueKey('error'),
        child: ErrorState(mensaje: DioClient.mapearError(error).mensaje, onRetry: onRetry),
      ),
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: contenido,
    );
  }
}
