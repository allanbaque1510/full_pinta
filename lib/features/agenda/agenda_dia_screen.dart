import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/estado_cita_pill.dart';
import '../../data/models/directory_models.dart';
import '../../data/models/scheduling_models.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

const _diasCortos = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

/// Agenda del local (§6): la vista que hace que el local registre TODO ahí
/// —incluidos walk-ins— o la disponibilidad que ve el cliente miente.
///
/// Nota para el backend (ver `context/plan-implementacion.md`): `GET
/// /auth/contexto` no expone el `profesional_id` de un contexto
/// `tipo: "profesional"` — solo `local_id`/`rol`. Sin eso, esta pantalla no
/// puede filtrar la agenda a "solo lo mío" para ese contexto y por ahora
/// muestra la agenda completa del local igual que al staff. Si se agrega
/// `profesional_id` a esa respuesta, acá se puede pasar como filtro.
///
/// Tampoco `Cita` trae el nombre del cliente ni el de cada servicio — se
/// muestra el teléfono cuando ya es visible (§3.3) y los servicios se
/// resuelven cruzando contra el perfil público del local, igual que en
/// `cita_detalle_screen.dart`.
class AgendaDiaScreen extends ConsumerStatefulWidget {
  final String localId;
  final String? profesionalPropioId;

  const AgendaDiaScreen({super.key, required this.localId, this.profesionalPropioId});

  @override
  ConsumerState<AgendaDiaScreen> createState() => _AgendaDiaScreenState();
}

class _AgendaDiaScreenState extends ConsumerState<AgendaDiaScreen> {
  DateTime _fecha = DateTime.now();
  String? _profesionalFiltro;
  List<Profesional> _profesionales = [];
  LocalPerfilPublico? _perfilLocal;
  AsyncValue<List<Cita>> _citas = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargarRoster();
    _cargar();
  }

  Future<void> _cargarRoster() async {
    try {
      final profesionales = await ref.read(staffingRepositoryProvider).listarProfesionales(widget.localId);
      final perfil = await ref.read(directoryRepositoryProvider).perfilPublicoLocal(widget.localId);
      if (mounted) {
        setState(() {
          _profesionales = profesionales;
          _perfilLocal = perfil;
        });
      }
    } catch (_) {
      // Solo enriquece nombres — la agenda funciona igual sin esto.
    }
  }

  Future<void> _cargar() async {
    setState(() => _citas = const AsyncValue.loading());
    try {
      final lista = await ref.read(schedulingRepositoryProvider).agendaDelLocal(
            widget.localId,
            fecha: AppFormatters.fechaIso(_fecha),
            profesionalId: widget.profesionalPropioId,
          );
      lista.sort((a, b) => a.inicio.compareTo(b.inicio));
      if (mounted) setState(() => _citas = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _citas = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  String _nombreProfesional(String id) {
    final match = _profesionales.where((p) => p.id == id);
    if (match.isEmpty) return 'Profesional';
    return match.first.alias ?? match.first.nombre;
  }

  String _nombreServicios(Cita cita) {
    final servicios = _perfilLocal?.servicios;
    if (servicios == null || cita.items.isEmpty) return '${cita.items.length} servicio(s)';
    final nombres = cita.items.map((i) {
      final match = servicios.where((s) => s.id == i.servicioLocalId);
      return match.isEmpty ? 'Servicio' : match.first.nombre;
    });
    return nombres.join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final citasFiltradas = _citas.whenData(
      (lista) => _profesionalFiltro == null ? lista : lista.where((c) => c.profesionalId == _profesionalFiltro).toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FilledButton.icon(
              onPressed: () => context.push('/locales/${widget.localId}/agenda/walk-in').then((_) => _cargar()),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('Walk-in'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- Selector de semana ----
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 7,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final dia = DateTime.now().subtract(const Duration(days: 2)).add(Duration(days: i));
                final esHoy = _esMismoDia(dia, DateTime.now());
                final activo = _esMismoDia(dia, _fecha);
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() => _fecha = dia);
                    _cargar();
                  },
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: activo ? scheme.primary : scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          esHoy ? 'HOY' : _diasCortos[dia.weekday % 7],
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: activo ? scheme.onPrimary : scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${dia.day}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: activo ? scheme.onPrimary : scheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ---- Encabezado + filtro de profesional ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                Expanded(child: Text(AppFormatters.fechaLegible(_fecha.toUtc()), style: Theme.of(context).textTheme.titleMedium)),
                _citas.when(
                  data: (lista) => Text(
                    lista.length == 1 ? '1 cita agendada' : '${lista.length} citas agendadas',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (_profesionales.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: _profesionalFiltro == null,
                      onSelected: (_) => setState(() => _profesionalFiltro = null),
                    ),
                  ),
                  ..._profesionales.map((p) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p.alias ?? p.nombre),
                          selected: _profesionalFiltro == p.id,
                          onSelected: (_) => setState(() => _profesionalFiltro = p.id),
                        ),
                      )),
                ],
              ),
            ),
          const SizedBox(height: 4),

          Expanded(
            child: citasFiltradas.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => ErrorState(mensaje: DioClient.mapearError(e).mensaje, onRetry: _cargar),
              data: (citas) => citas.isEmpty
                  ? const EmptyState(mensaje: 'Sin citas para este día.', icono: Icons.event_available_outlined)
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: citas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final c = citas[i];
                          final esWalkIn = c.canal == 'local';
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => context.push('/locales/${widget.localId}/agenda/${c.id}').then((_) => _cargar()),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(AppFormatters.horaLegible(c.inicio), style: Theme.of(context).textTheme.headlineSmall),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: scheme.surfaceContainerHigh,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text('#${c.codigo}', style: Theme.of(context).textTheme.labelSmall),
                                        ),
                                        const Spacer(),
                                        EstadoCitaPill(estado: c.estado),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c.clienteTelefono ?? 'Cliente',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _nombreServicios(c),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                          ),
                                        ),
                                        Text(
                                          ' • ',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                        ),
                                        Text(
                                          esWalkIn ? 'Walk-in directo' : 'Reserva app',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.tertiary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.content_cut, size: 12, color: scheme.onSurfaceVariant),
                                              const SizedBox(width: 4),
                                              Text(_nombreProfesional(c.profesionalId), style: Theme.of(context).textTheme.labelSmall),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right, size: 18),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _esMismoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
