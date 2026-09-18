import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/star_rating.dart';
import '../../data/models/reviews_models.dart';
import '../../state/repository_providers.dart';

/// A diferencia del perfil público (solo `publicada`), acá el staff ve
/// **todos** los estados de reseña — necesita saber qué está oculto o en
/// revisión (§8).
class LocalResenasScreen extends ConsumerStatefulWidget {
  final String localId;

  const LocalResenasScreen({super.key, required this.localId});

  @override
  ConsumerState<LocalResenasScreen> createState() => _LocalResenasScreenState();
}

class _LocalResenasScreenState extends ConsumerState<LocalResenasScreen> {
  bool _cargando = true;
  String? _error;
  List<Resena> _resenas = [];
  final Set<String> _respondiendo = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await ref.read(reviewsRepositoryProvider).listarResenasDelLocal(widget.localId);
      if (mounted) setState(() => _resenas = lista);
    } catch (e) {
      if (mounted) setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _responder(Resena resena) async {
    final ctrl = TextEditingController(text: resena.respuestaLocal ?? '');
    final respuesta = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responder reseña'),
        content: TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Gracias por tu visita...')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(ctrl.text.trim()), child: const Text('Enviar')),
        ],
      ),
    );
    if (respuesta == null || respuesta.isEmpty) return;
    setState(() => _respondiendo.add(resena.id));
    try {
      await ref.read(reviewsRepositoryProvider).responder(resena.id, respuesta);
      await _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _respondiendo.remove(resena.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reseñas')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(mensaje: _error!, onRetry: _cargar)
              : _resenas.isEmpty
                  ? const EmptyState(mensaje: 'Todavía no tienes reseñas.', icono: Icons.star_outline)
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _resenas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final r = _resenas[i];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      StarRatingView(puntaje: r.puntajeLocal.toDouble()),
                                      const Spacer(),
                                      Chip(label: Text(textoEstadoResena(r.estado)), visualDensity: VisualDensity.compact),
                                    ],
                                  ),
                                  if (r.comentario != null && r.comentario!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(r.comentario!),
                                  ],
                                  if (r.respuestaLocal != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Tu respuesta: ${r.respuestaLocal}'),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: PrimaryButton(
                                        label: 'Responder',
                                        isLoading: _respondiendo.contains(r.id),
                                        onPressed: () => _responder(r),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
