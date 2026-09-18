import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/color_dot.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/menu_access_tile.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/models/directory_models.dart';
import '../../data/models/scheduling_models.dart';
import '../../state/repository_providers.dart';

/// Hub de administración de un local: horarios, amenidades, fotos,
/// servicios, productos, personal, recursos, agenda y reseñas — cada uno
/// en su propia pantalla (mismo patrón CRUD de `core/widgets/list_scaffold.dart`).
class LocalAdminScreen extends ConsumerStatefulWidget {
  final String localId;

  const LocalAdminScreen({super.key, required this.localId});

  @override
  ConsumerState<LocalAdminScreen> createState() => _LocalAdminScreenState();
}

class _LocalAdminScreenState extends ConsumerState<LocalAdminScreen> {
  Local? _local;
  LocalPerfilPublico? _perfilPublico;
  List<Cita> _citasHoy = [];
  int _totalServicios = 0;
  int _totalProfesionales = 0;
  bool _cargando = true;
  String? _error;
  bool _cambiandoEstado = false;

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
      final directorio = ref.read(directoryRepositoryProvider);
      final local = await directorio.obtenerLocal(widget.localId);
      if (!mounted) return;
      setState(() => _local = local);

      // El resto es "mejor esfuerzo": si alguna falla (ej. perfil público de
      // un local en borrador, que da 404 a propósito), la pantalla igual
      // funciona con lo esencial ya cargado arriba.
      final hoy = AppFormatters.fechaIso(DateTime.now());

      Future<LocalPerfilPublico?> cargarPerfil() async {
        try {
          return await directorio.perfilPublicoLocal(widget.localId);
        } catch (_) {
          return null;
        }
      }

      Future<List<Cita>> cargarCitasHoy() async {
        try {
          return await ref.read(schedulingRepositoryProvider).agendaDelLocal(widget.localId, fecha: hoy);
        } catch (_) {
          return [];
        }
      }

      Future<int> cargarTotalServicios() async {
        try {
          final lista = await ref.read(catalogRepositoryProvider).listarServiciosLocal(widget.localId);
          return lista.where((s) => s.activo).length;
        } catch (_) {
          return 0;
        }
      }

      Future<int> cargarTotalProfesionales() async {
        try {
          final lista = await ref.read(staffingRepositoryProvider).listarProfesionales(widget.localId);
          return lista.length;
        } catch (_) {
          return 0;
        }
      }

      final perfilFuture = cargarPerfil();
      final citasFuture = cargarCitasHoy();
      final serviciosFuture = cargarTotalServicios();
      final profesionalesFuture = cargarTotalProfesionales();

      final perfil = await perfilFuture;
      final citas = await citasFuture;
      final totalServicios = await serviciosFuture;
      final totalProfesionales = await profesionalesFuture;
      if (!mounted) return;
      setState(() {
        _perfilPublico = perfil;
        _citasHoy = citas;
        _totalServicios = totalServicios;
        _totalProfesionales = totalProfesionales;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarEstado(String objetivo) async {
    if (objetivo == _local!.estado) return;
    setState(() => _cambiandoEstado = true);
    try {
      final repo = ref.read(directoryRepositoryProvider);
      final actualizado = objetivo == 'activo' ? await repo.activarLocal(widget.localId) : await repo.pausarLocal(widget.localId);
      if (mounted) setState(() => _local = actualizado);
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cambiandoEstado = false);
    }
  }

  String? _horarioDeHoy() {
    final horarios = _perfilPublico?.horarios;
    if (horarios == null) return null;
    final hoy = DateTime.now().weekday % 7;
    final delDia = horarios.where((h) => h.diaSemana == hoy);
    if (delDia.isEmpty) return 'Cerrado hoy';
    return 'Abierto hoy hasta las ${delDia.last.cierra}';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _local == null) {
      return Scaffold(appBar: AppBar(), body: ErrorState(mensaje: _error ?? 'No se pudo cargar.', onRetry: _cargar));
    }

    final local = _local!;
    final scheme = Theme.of(context).colorScheme;
    final horarioHoy = _horarioDeHoy();

    return Scaffold(
      appBar: AppBar(title: const Text('Panel del negocio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Estado del local ----
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ColorDot(color: scheme.tertiary, tamano: 8),
                    const SizedBox(width: 6),
                    Text(local.direccion, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(local.nombre, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Activo'),
                      selected: local.estado == 'activo',
                      onSelected: _cambiandoEstado ? null : (_) => _cambiarEstado('activo'),
                    ),
                    ChoiceChip(
                      label: const Text('Pausado'),
                      selected: local.estado == 'pausado',
                      onSelected: _cambiandoEstado || local.estado == 'borrador' ? null : (_) => _cambiarEstado('pausado'),
                    ),
                    ChoiceChip(label: const Text('Borrador'), selected: local.estado == 'borrador', onSelected: null),
                  ],
                ),
                if (horarioHoy != null) ...[
                  const SizedBox(height: 12),
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    radio: 10,
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(child: Text(horarioHoy, style: Theme.of(context).textTheme.labelMedium)),
                        Text(
                          _citasHoy.length == 1 ? '1 cita programada' : '${_citasHoy.length} citas programadas',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('GESTIÓN DEL ESTABLECIMIENTO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: 8),

          MenuAccessTile(
            icono: Icons.event_note_outlined,
            titulo: 'Agenda',
            subtitulo: 'Ver turnos del día y calendario completo',
            contador: '${_citasHoy.length} hoy',
            onTap: () => context.push('/locales/${local.id}/agenda'),
          ),
          MenuAccessTile(
            icono: Icons.schedule_outlined,
            titulo: 'Horarios',
            subtitulo: 'Días laborables, aperturas y turnos',
            onTap: () => context.push('/locales/${local.id}/horarios'),
          ),
          MenuAccessTile(
            icono: Icons.design_services_outlined,
            titulo: 'Servicios y precios',
            subtitulo: 'Catálogo, duraciones y costos',
            contador: '$_totalServicios items',
            onTap: () => context.push('/locales/${local.id}/servicios'),
          ),
          MenuAccessTile(
            icono: Icons.shopping_bag_outlined,
            titulo: 'Productos',
            subtitulo: 'Inventario de venta para clientes',
            onTap: () => context.push('/locales/${local.id}/productos'),
          ),
          MenuAccessTile(
            icono: Icons.people_outline,
            titulo: 'Personal',
            subtitulo: 'Barberos, estilistas y permisos',
            contador: '$_totalProfesionales activos',
            onTap: () => context.push('/locales/${local.id}/personal'),
          ),
          MenuAccessTile(
            icono: Icons.chair_outlined,
            titulo: 'Recursos',
            subtitulo: 'Sillas, sillones, mesas de manicure, cabinas',
            onTap: () => context.push('/locales/${local.id}/recursos'),
          ),
          MenuAccessTile(
            icono: Icons.event_busy_outlined,
            titulo: 'Cierres y excepciones',
            subtitulo: 'Feriados, descansos y bloqueos temporales',
            onTap: () => context.push('/locales/${local.id}/excepciones'),
          ),
          MenuAccessTile(
            icono: Icons.local_cafe_outlined,
            titulo: 'Amenidades',
            subtitulo: 'Wifi, café cortesía, parqueo, aire acondicionado',
            onTap: () => context.push('/locales/${local.id}/amenidades'),
          ),
          MenuAccessTile(
            icono: Icons.photo_library_outlined,
            titulo: 'Fotos',
            subtitulo: 'Galería del local y puestos de trabajo',
            onTap: () => context.push('/locales/${local.id}/fotos'),
          ),
          MenuAccessTile(
            icono: Icons.reviews_outlined,
            titulo: 'Reseñas',
            subtitulo: 'Comentarios de clientes y respuestas',
            contador: _perfilPublico != null && _perfilPublico!.resenas.total > 0
                ? '★ ${_perfilPublico!.resenas.promedio.toStringAsFixed(1)}'
                : null,
            onTap: () => context.push('/locales/${local.id}/resenas'),
          ),
          MenuAccessTile(
            icono: Icons.add_shopping_cart_outlined,
            titulo: 'Solicitar servicio nuevo',
            subtitulo: 'Acceso para sugerir nuevas categorías al catálogo',
            onTap: () => context.push('/locales/${local.id}/solicitudes-catalogo'),
          ),

          if (_perfilPublico != null && _perfilPublico!.fotos.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Vistazo rápido del local', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${_perfilPublico!.fotos.length} fotos',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _perfilPublico!.fotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(imageUrl: _perfilPublico!.fotos[i].url, width: 84, height: 84, fit: BoxFit.cover),
                ),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => context.push('/locales/${local.id}/agenda'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Ir a agenda'),
          ),
        ),
      ),
    );
  }
}
