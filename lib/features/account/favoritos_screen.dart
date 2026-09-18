import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/photo_carousel.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/tag_pill.dart';
import '../../data/models/favorito_model.dart';
import '../../state/repository_providers.dart';

enum _Filtro { todos, locales, profesionales }

class FavoritosScreen extends ConsumerStatefulWidget {
  const FavoritosScreen({super.key});

  @override
  ConsumerState<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends ConsumerState<FavoritosScreen> {
  bool _cargando = true;
  String? _error;
  List<Favorito> _favoritos = [];
  _Filtro _filtro = _Filtro.todos;
  bool _mostrarAyuda = false;

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
      final lista = await ref.read(identityRepositoryProvider).obtenerFavoritos();
      if (!mounted) return;
      setState(() => _favoritos = lista);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  final Set<String> _quitando = {};

  Future<void> _quitar(Favorito favorito) async {
    setState(() => _quitando.add(favorito.id));
    try {
      await ref.read(identityRepositoryProvider).alternarFavorito(
            localId: favorito.local?.id,
            profesionalId: favorito.profesional?.id,
          );
      if (mounted) setState(() => _favoritos.remove(favorito));
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _quitando.remove(favorito.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalLocales = _favoritos.where((f) => f.esLocal).length;
    final totalProfesionales = _favoritos.length - totalLocales;
    final visibles = switch (_filtro) {
      _Filtro.todos => _favoritos,
      _Filtro.locales => _favoritos.where((f) => f.esLocal).toList(),
      _Filtro.profesionales => _favoritos.where((f) => !f.esLocal).toList(),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(mensaje: _error!, onRetry: _cargar)
              : _favoritos.isEmpty
                  ? const EmptyState(mensaje: 'Todavía no tienes favoritos.', icono: Icons.favorite_border)
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: Text('Todos ${_favoritos.length}'),
                                selected: _filtro == _Filtro.todos,
                                onSelected: (_) => setState(() => _filtro = _Filtro.todos),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text('Locales $totalLocales'),
                                selected: _filtro == _Filtro.locales,
                                onSelected: (_) => setState(() => _filtro = _Filtro.locales),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text('Profesionales $totalProfesionales'),
                                selected: _filtro == _Filtro.profesionales,
                                onSelected: (_) => setState(() => _filtro = _Filtro.profesionales),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: visibles.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              if (i == visibles.length) {
                                return Card(
                                  child: ExpansionTile(
                                    onExpansionChanged: (v) => setState(() => _mostrarAyuda = v),
                                    initiallyExpanded: _mostrarAyuda,
                                    leading: const Icon(Icons.help_outline),
                                    title: const Text('¿Cómo funcionan los favoritos?'),
                                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    children: [
                                      Text(
                                        'Guarda locales y profesionales que te gusten para encontrarlos rápido después. '
                                        'No afecta tus citas ni notifica al local.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return _FavoritoCard(
                                favorito: visibles[i],
                                quitando: _quitando.contains(visibles[i].id),
                                onQuitar: () => _quitar(visibles[i]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _FavoritoCard extends StatelessWidget {
  final Favorito favorito;
  final bool quitando;
  final VoidCallback onQuitar;

  const _FavoritoCard({required this.favorito, required this.quitando, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final esLocal = favorito.esLocal;
    final nombre = esLocal ? favorito.local!.nombre : favorito.profesional!.nombre;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NetworkAvatar(
                  url: esLocal ? favorito.local!.fotoUrl : favorito.profesional?.fotoUrl,
                  radio: 26,
                  iconoFallback: esLocal ? Icons.storefront_outlined : Icons.person,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TagPill(texto: esLocal ? 'LOCAL' : 'PROFESIONAL', color: esLocal ? scheme.tertiary : scheme.secondary),
                      const SizedBox(height: 4),
                      Text(nombre, style: Theme.of(context).textTheme.titleMedium),
                      if (esLocal && favorito.local!.direccion != null)
                        Text(
                          favorito.local!.direccion!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      if (!esLocal && favorito.profesional?.alias != null)
                        Text(
                          '"${favorito.profesional!.alias}"',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: quitando ? null : onQuitar,
                  icon: quitando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                  label: const Text('Guardado'),
                ),
                const Spacer(),
                PrimaryButton(
                  label: esLocal ? 'Ver local' : 'Ver perfil',
                  icon: Icons.chevron_right,
                  onPressed: () => context.push(esLocal ? '/local/${favorito.local!.id}' : '/profesional/${favorito.profesional!.id}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
