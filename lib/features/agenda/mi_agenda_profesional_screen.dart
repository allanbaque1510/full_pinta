import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/estado_cita_pill.dart';
import '../../data/models/scheduling_models.dart';
import '../../state/repository_providers.dart';
import '../../state/session_controller.dart';

/// Agenda propia del profesional (§3.2): `GET /mis-citas-profesional`, que
/// cruza todos los locales donde trabaja. Reemplaza a `AgendaDiaScreen` en el
/// contexto `profesional`, que mostraba la agenda completa del local.
///
/// Si la cuenta no tiene un `Profesional` vinculado el backend responde 403
/// `no_es_profesional`: se explica que el local debe vincular la cuenta.
class MiAgendaProfesionalScreen extends ConsumerStatefulWidget {
  const MiAgendaProfesionalScreen({super.key});

  @override
  ConsumerState<MiAgendaProfesionalScreen> createState() => _MiAgendaProfesionalScreenState();
}

class _MiAgendaProfesionalScreenState extends ConsumerState<MiAgendaProfesionalScreen> {
  static const _filtrosEstado = <String?, String>{
    null: 'Todas',
    'confirmada': 'Confirmadas',
    'en_curso': 'En curso',
    'completada': 'Completadas',
    'no_show': 'No se presentó',
  };

  String? _estado;
  String? _localId;
  List<Cita> _citas = [];
  bool _cargando = true;
  String? _error;
  bool _noEsProfesional = false;
  String? _procesandoId;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
      _noEsProfesional = false;
    });
    try {
      final lista = await ref.read(schedulingRepositoryProvider).misCitasProfesional(
            estado: _estado,
            localId: _localId,
          );
      // El backend responde por inicio descendente; una agenda se lee de
      // arriba hacia abajo en el orden del día.
      lista.sort((a, b) => a.inicio.compareTo(b.inicio));
      if (mounted) setState(() => _citas = lista);
    } catch (e) {
      final error = DioClient.mapearError(e);
      if (!mounted) return;
      setState(() {
        if (error.codigo == 'no_es_profesional') {
          _noEsProfesional = true;
        } else {
          _error = error.mensaje;
        }
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _ejecutar(Cita cita, Future<Cita> Function() accion) async {
    setState(() => _procesandoId = cita.id);
    try {
      final actualizada = await accion();
      if (!mounted) return;
      setState(() {
        final i = _citas.indexWhere((c) => c.id == cita.id);
        if (i >= 0) _citas[i] = actualizada;
      });
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _procesandoId = null);
    }
  }

  Future<void> _completar(Cita cita) async {
    final propinaCtrl = TextEditingController();
    final propina = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar cita'),
        content: TextField(
          controller: propinaCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Propina (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(double.tryParse(propinaCtrl.text.replaceAll(',', '.')) ?? 0),
            child: const Text('Completar'),
          ),
        ],
      ),
    );
    propinaCtrl.dispose();
    if (propina == null) return;
    await _ejecutar(cita, () => ref.read(schedulingRepositoryProvider).completar(cita.id, propina: propina));
  }

  Future<void> _noShow(Cita cita) async {
    final ok = await confirmarDialogo(
      context,
      titulo: 'Marcar no-show',
      mensaje: 'El cliente no se presentó. Esto cuenta en su historial de confiabilidad.',
      textoConfirmar: 'Marcar',
      destructivo: true,
    );
    if (!ok) return;
    await _ejecutar(cita, () => ref.read(schedulingRepositoryProvider).noShow(cita.id));
  }

  /// Nombres de local para el filtro, tomados del contexto de acceso
  /// (`GET /auth/contexto` ya trae `local_nombre` de cada contexto profesional).
  Map<String, String> _localesDelProfesional() {
    final acceso = ref.read(sessionControllerProvider).contextoAcceso;
    final mapa = <String, String>{};
    for (final c in acceso?.contextos ?? const []) {
      if (c.esProfesional && c.localId != null) mapa[c.localId!] = c.localNombre ?? 'Local';
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locales = _localesDelProfesional();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi agenda')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final e in _filtrosEstado.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _estado == e.key,
                      onSelected: (_) {
                        setState(() => _estado = e.key);
                        _cargar();
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (locales.length > 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todos los locales'),
                      selected: _localId == null,
                      onSelected: (_) {
                        setState(() => _localId = null);
                        _cargar();
                      },
                    ),
                  ),
                  for (final l in locales.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(l.value),
                        selected: _localId == l.key,
                        onSelected: (_) {
                          setState(() => _localId = l.key);
                          _cargar();
                        },
                      ),
                    ),
                ],
              ),
            ),
          Expanded(child: _cuerpo(scheme, locales)),
        ],
      ),
    );
  }

  Widget _cuerpo(ColorScheme scheme, Map<String, String> locales) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_noEsProfesional) {
      return const EmptyState(
        mensaje: 'Tu cuenta todavía no está vinculada a un perfil de profesional. '
            'Pídele al local que la vincule con tu teléfono.',
        icono: Icons.link_off,
      );
    }
    if (_error != null) return ErrorState(mensaje: _error!, onRetry: _cargar);
    if (_citas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            EmptyState(mensaje: 'No tienes citas con este filtro.', icono: Icons.event_available_outlined),
          ],
        ),
      );
    }

    // Agrupa por día (hora de Guayaquil) con un encabezado por grupo.
    final filas = <Object>[];
    String? diaActual;
    for (final c in _citas) {
      final dia = AppFormatters.fechaIso(AppFormatters.aGuayaquil(c.inicio));
      if (dia != diaActual) {
        diaActual = dia;
        filas.add(AppFormatters.fechaLegible(c.inicio));
      }
      filas.add(c);
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: filas.length,
        itemBuilder: (context, i) {
          final fila = filas[i];
          if (fila is String) {
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(fila, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary)),
            );
          }
          return _TarjetaCita(
            cita: fila as Cita,
            nombreLocal: locales[(fila).localId],
            procesando: _procesandoId == fila.id,
            onAbrir: () => context.push('/locales/${fila.localId}/agenda/${fila.id}').then((_) => _cargar()),
            onIniciar: () => _ejecutar(fila, () => ref.read(schedulingRepositoryProvider).iniciar(fila.id)),
            onCompletar: () => _completar(fila),
            onNoShow: () => _noShow(fila),
          );
        },
      ),
    );
  }
}

class _TarjetaCita extends StatelessWidget {
  final Cita cita;
  final String? nombreLocal;
  final bool procesando;
  final VoidCallback onAbrir;
  final VoidCallback onIniciar;
  final VoidCallback onCompletar;
  final VoidCallback onNoShow;

  const _TarjetaCita({
    required this.cita,
    required this.nombreLocal,
    required this.procesando,
    required this.onAbrir,
    required this.onIniciar,
    required this.onCompletar,
    required this.onNoShow,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final propina = double.tryParse(cita.propina) ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onAbrir,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${AppFormatters.horaLegible(cita.inicio)} - ${AppFormatters.horaLegible(cita.fin)}',
                      style: texto.titleMedium),
                  const Spacer(),
                  EstadoCitaPill(estado: cita.estado),
                ],
              ),
              const SizedBox(height: 6),
              Text(cita.clienteTelefono ?? 'Cliente', style: texto.bodyLarge),
              Text(
                [
                  if (nombreLocal != null) nombreLocal!,
                  '${cita.items.length} servicio(s)',
                  AppFormatters.dinero(cita.precioTotal),
                  if (propina > 0) 'propina ${AppFormatters.dinero(cita.propina)}',
                ].join(' · '),
                style: texto.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (cita.notaCliente != null && cita.notaCliente!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Nota: ${cita.notaCliente}', style: texto.bodySmall),
              ],
              if (cita.estado == 'confirmada' || cita.estado == 'en_curso') ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (cita.estado == 'confirmada')
                      FilledButton(
                        onPressed: procesando ? null : onIniciar,
                        child: const Text('El cliente llegó'),
                      ),
                    if (cita.estado == 'en_curso')
                      FilledButton(
                        onPressed: procesando ? null : onCompletar,
                        child: const Text('Completar'),
                      ),
                    OutlinedButton(
                      onPressed: procesando ? null : onNoShow,
                      style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                      child: const Text('No se presentó'),
                    ),
                    if (procesando)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
