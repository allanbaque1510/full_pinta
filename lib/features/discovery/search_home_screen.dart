import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/location.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/fullpinta_wordmark.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/models/catalog_models.dart';
import '../../data/models/directory_models.dart';
import '../../state/repository_providers.dart';
import 'search_filters_sheet.dart';

class SearchHomeScreen extends ConsumerStatefulWidget {
  const SearchHomeScreen({super.key});

  @override
  ConsumerState<SearchHomeScreen> createState() => _SearchHomeScreenState();
}

class _SearchHomeScreenState extends ConsumerState<SearchHomeScreen> {
  LatLng? _ubicacion;
  bool _cargando = true;
  String? _error;
  List<LocalBusqueda> _resultados = [];

  SearchFilters _filtros = const SearchFilters();

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      _ubicacion ??= await AppLocation.obtenerUbicacionActual();
      final repo = ref.read(directoryRepositoryProvider);
      final resultados = await repo.buscarLocales(
        lat: _ubicacion!.lat,
        lng: _ubicacion!.lng,
        rubro: _filtros.rubro,
        precioMin: _filtros.precioMin,
        precioMax: _filtros.precioMax,
        amenidades: _filtros.amenidades.isEmpty ? null : _filtros.amenidades.toList(),
        disponible: _filtros.soloDisponibles ? true : null,
        abiertoAhora: _filtros.abiertoAhora ? true : null,
      );
      if (!mounted) return;
      setState(() => _resultados = resultados);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirFiltros() async {
    final nuevos = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SearchFiltersSheet(filtrosIniciales: _filtros),
    );
    if (nuevos != null) {
      setState(() => _filtros = nuevos);
      _cargarTodo();
    }
  }


  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarTodo,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const Row(children: [FullPintaWordmark(tamano: 26)]),
              const SizedBox(height: 4),
              Text('Descubre belleza cerca de ti', style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _abrirFiltros,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: scheme.onSurfaceVariant, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _resumenFiltros(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Badge(
                    isLabelVisible: _filtros.activos,
                    child: IconButton.outlined(
                      onPressed: _abrirFiltros,
                      icon: const Icon(Icons.tune),
                      style: IconButton.styleFrom(side: BorderSide(color: scheme.outlineVariant)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 84,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoriaCirculo(
                      etiqueta: 'Todo',
                      icono: Icons.apps_rounded,
                      activo: _filtros.rubro == null,
                      onTap: () {
                        setState(() => _filtros = _filtros.copyWith(limpiarRubro: true));
                        _cargarTodo();
                      },
                    ),
                    ...rubrosDisponibles.where((v) => v != 'mascotas').map(
                          (v) => _CategoriaCirculo(
                            etiqueta: etiquetaRubro(v),
                            icono: _iconoRubro(v),
                            activo: _filtros.rubro == v,
                            onTap: () {
                              setState(() => _filtros = _filtros.copyWith(rubro: v));
                              _cargarTodo();
                            },
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: Text('Locales cerca de ti', style: textTheme.titleMedium)),
                  if (_filtros.activos)
                    TextButton(
                      onPressed: () {
                        setState(() => _filtros = const SearchFilters());
                        _cargarTodo();
                      },
                      child: const Text('Limpiar filtros'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_cargando)
                const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                ErrorState(mensaje: _error!, onRetry: _cargarTodo)
              else if (_resultados.isEmpty)
                const EmptyState(
                  mensaje: 'No encontramos locales con estos filtros. Prueba ampliando el radio o quitando alguno.',
                  icono: Icons.storefront_outlined,
                )
              else
                ..._resultados.map((l) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _LocalCard(local: l))),
            ],
          ),
        ),
      ),
    );
  }

  String _resumenFiltros() {
    if (!_filtros.activos) return '¿Qué quieres hacerte? Barbería, uñas, estética...';
    final partes = <String>[];
    if (_filtros.rubro != null) partes.add(etiquetaRubro(_filtros.rubro!));
    if (_filtros.abiertoAhora) partes.add('Abierto ahora');
    if (_filtros.soloDisponibles) partes.add('Disponible hoy');
    if (_filtros.amenidades.isNotEmpty) partes.add('${_filtros.amenidades.length} amenidades');
    return partes.isEmpty ? 'Filtros aplicados' : partes.join(' · ');
  }

  IconData _iconoRubro(String rubro) => switch (rubro) {
        'barberia' => Icons.content_cut,
        'estetica' => Icons.face_retouching_natural,
        'unas' => Icons.brush_outlined,
        _ => Icons.spa_outlined,
      };
}

class _CategoriaCirculo extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final bool activo;
  final VoidCallback onTap;

  const _CategoriaCirculo({required this.etiqueta, required this.icono, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          width: 60,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activo ? scheme.primary : scheme.primaryContainer,
                ),
                child: Icon(icono, color: activo ? scheme.onPrimary : scheme.primary),
              ),
              const SizedBox(height: 6),
              Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: activo ? scheme.primary : scheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalCard extends StatelessWidget {
  final LocalBusqueda local;

  const _LocalCard({required this.local});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/local/${local.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primaryContainer, scheme.surfaceContainerHigh],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.storefront_outlined, size: 36, color: scheme.primary.withValues(alpha: 0.5)),
                  ),
                ),
                if (local.verificado)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: StatusBadge(icono: Icons.verified, texto: 'Verificado', color: scheme.tertiary),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(local.nombre, style: textTheme.titleMedium)),
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.estrella),
                      const SizedBox(width: 3),
                      Text(
                        local.scoreRanking > 0 ? local.scoreRanking.toStringAsFixed(1) : 'Nuevo',
                        style: textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${AppFormatters.distancia(local.distanciaM)} · ${local.direccion}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push('/local/${local.id}'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                    child: const Text('Ver disponibilidad'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
