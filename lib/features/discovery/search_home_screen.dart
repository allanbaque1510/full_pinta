import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/location.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
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
        vertical: _filtros.vertical,
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset('assets/branding/logo.png', width: 28, height: 28),
            const SizedBox(width: 10),
            const Text('FullPinta'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _abrirFiltros,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: scheme.onSurfaceVariant, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            _resumenFiltros(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Badge(
                  isLabelVisible: _filtros.activos,
                  child: IconButton.filledTonal(
                    onPressed: _abrirFiltros,
                    icon: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [null, ...verticalesDisponibles.where((v) => v != 'mascotas')].map((v) {
                final activo = _filtros.vertical == v;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(v == null ? 'Todas' : etiquetaVertical(v)),
                    selected: activo,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _filtros = _filtros.copyWith(vertical: v, limpiarVertical: v == null));
                      _cargarTodo();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargarTodo,
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ErrorState(mensaje: _error!, onRetry: _cargarTodo)
                      : _resultados.isEmpty
                          ? const EmptyState(
                              mensaje:
                                  'No encontramos locales con estos filtros. Prueba ampliando el radio o quitando alguno.',
                              icono: Icons.storefront_outlined,
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _resultados.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) => _LocalCard(local: _resultados[i]),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  String _resumenFiltros() {
    if (!_filtros.activos) return 'Buscar salón, uñas, spa, barbería...';
    final partes = <String>[];
    if (_filtros.vertical != null) partes.add(etiquetaVertical(_filtros.vertical!));
    if (_filtros.abiertoAhora) partes.add('Abierto ahora');
    if (_filtros.soloDisponibles) partes.add('Disponible hoy');
    if (_filtros.amenidades.isNotEmpty) partes.add('${_filtros.amenidades.length} amenidades');
    return partes.isEmpty ? 'Filtros aplicados' : partes.join(' · ');
  }
}

class _LocalCard extends StatelessWidget {
  final LocalBusqueda local;

  const _LocalCard({required this.local});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                  height: 84,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary.withValues(alpha: 0.28), scheme.surfaceContainerHigh],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.storefront_outlined, size: 30, color: scheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
                if (local.verificado)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: StatusBadge(icono: Icons.verified, texto: 'Verificado', color: scheme.primary),
                  ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: scheme.primary),
                        const SizedBox(width: 3),
                        Text(
                          local.scoreRanking > 0 ? local.scoreRanking.toStringAsFixed(1) : 'Nuevo',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(local.nombre, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    local.direccion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.near_me_outlined, size: 14, color: scheme.tertiary),
                      const SizedBox(width: 4),
                      Text(AppFormatters.distancia(local.distanciaM), style: Theme.of(context).textTheme.labelSmall),
                      const Spacer(),
                      Text(
                        'Ver perfil',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.primary),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: scheme.primary),
                    ],
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
