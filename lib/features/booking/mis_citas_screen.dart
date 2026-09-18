import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/estado_cita_pill.dart';
import '../../data/models/scheduling_models.dart';
import '../../state/repository_providers.dart';

class MisCitasScreen extends ConsumerStatefulWidget {
  const MisCitasScreen({super.key});

  @override
  ConsumerState<MisCitasScreen> createState() => _MisCitasScreenState();
}

const _filtroTodas = 'todas';
const _filtrosEstado = [
  _filtroTodas,
  'reservada',
  'confirmada',
  'en_curso',
  'completada',
  'cancelada_cliente',
  'cancelada_local',
  'no_show',
];

class _MisCitasScreenState extends ConsumerState<MisCitasScreen> {
  bool _cargando = true;
  String? _error;
  List<Cita> _citas = [];
  final Map<String, String> _nombresLocal = {};
  String _filtro = _filtroTodas;

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
      final citas = await ref.read(schedulingRepositoryProvider).misCitas(
            estado: _filtro == _filtroTodas ? null : _filtro,
          );
      if (!mounted) return;
      setState(() => _citas = citas);
      _cargarNombresLocales(citas);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarNombresLocales(List<Cita> citas) async {
    final repo = ref.read(directoryRepositoryProvider);
    final idsFaltantes = citas.map((c) => c.localId).toSet()..removeWhere(_nombresLocal.containsKey);
    for (final id in idsFaltantes) {
      try {
        final local = await repo.perfilPublicoLocal(id);
        _nombresLocal[id] = local.nombre;
      } catch (_) {
        _nombresLocal[id] = 'Local';
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis citas')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _filtrosEstado.map((f) {
                final activo = _filtro == f;
                final scheme = Theme.of(context).colorScheme;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(f == _filtroTodas ? 'Todas' : textoEstadoCita(f)),
                    selected: activo,
                    showCheckmark: false,
                    avatar: activo ? Icon(Icons.circle, size: 8, color: scheme.primary) : null,
                    onSelected: (_) {
                      setState(() => _filtro = f);
                      _cargar();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorState(mensaje: _error!, onRetry: _cargar)
                    : _citas.isEmpty
                        ? const EmptyState(mensaje: 'Todavía no tienes citas.', icono: Icons.event_note_outlined)
                        : RefreshIndicator(
                            onRefresh: _cargar,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _citas.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) => _CitaCard(
                                cita: _citas[i],
                                nombreLocal: _nombresLocal[_citas[i].localId] ?? 'Local',
                                onTap: () => context.push('/mis-citas/${_citas[i].id}'),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CitaCard extends StatelessWidget {
  final Cita cita;
  final String nombreLocal;
  final VoidCallback onTap;

  const _CitaCard({required this.cita, required this.nombreLocal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = colorEstadoCita(cita.estado);
    final esTerminalMala = cita.estado.startsWith('cancelada') || cita.estado == 'no_show' || cita.estado == 'expirada';

    return Opacity(
      opacity: esTerminalMala ? 0.85 : 1,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.storefront_outlined, color: scheme.onSurfaceVariant, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombreLocal, style: Theme.of(context).textTheme.headlineSmall, overflow: TextOverflow.ellipsis),
                          Text(
                            cita.items.length == 1 ? '1 servicio' : '${cita.items.length} servicios',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          Row(
                            children: [
                              Icon(
                                cita.canal == 'local' ? Icons.storefront_outlined : Icons.event_seat_outlined,
                                size: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cita.codigo,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    EstadoCitaPill(estado: cita.estado),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(AppFormatters.fechaHoraLegible(cita.inicio), style: Theme.of(context).textTheme.labelMedium)),
                      Text(
                        AppFormatters.dinero(cita.precioTotal),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
