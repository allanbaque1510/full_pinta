import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/icon_avatar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/models/catalog_models.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

/// Walk-in (§6.6): un cliente que llega sin cita — ocupa el slot igual que
/// uno de la app (mismo constraint `EXCLUDE`), pero nace `confirmada`
/// directo, sin hold. Si el teléfono no existe todavía, el backend crea un
/// usuario mínimo sin contraseña (§6.7) — acá nunca hace falta un
/// `cliente_id`, con nombre+teléfono alcanza.
class WalkInFormScreen extends ConsumerStatefulWidget {
  final String localId;

  const WalkInFormScreen({super.key, required this.localId});

  @override
  ConsumerState<WalkInFormScreen> createState() => _WalkInFormScreenState();
}

class _WalkInFormScreenState extends ConsumerState<WalkInFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _cargandoOpciones = true;
  String? _error;
  List<Profesional> _profesionales = [];
  List<ServicioLocal> _servicios = [];
  String? _profesionalId;
  final Set<String> _servicioIds = {};
  DateTime _inicio = DateTime.now();
  _ModoHora _modoHora = _ModoHora.ahora;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarOpciones();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarOpciones() async {
    try {
      final profesionales = await ref.read(staffingRepositoryProvider).listarProfesionales(widget.localId);
      final servicios = await ref.read(catalogRepositoryProvider).listarServiciosLocal(widget.localId);
      if (!mounted) return;
      setState(() {
        _profesionales = profesionales;
        _servicios = servicios.where((s) => s.activo).toList();
        if (profesionales.length == 1) _profesionalId = profesionales.first.id;
      });
    } catch (e) {
      if (mounted) setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargandoOpciones = false);
    }
  }

  Future<void> _elegirHora() async {
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_inicio));
    if (hora == null) return;
    final ahora = DateTime.now();
    setState(() {
      _inicio = DateTime(ahora.year, ahora.month, ahora.day, hora.hour, hora.minute);
      _modoHora = _ModoHora.personalizada;
    });
  }

  double get _totalPrecio => _servicios
      .where((s) => _servicioIds.contains(s.id))
      .fold(0.0, (acc, s) => acc + (double.tryParse(s.precio) ?? 0));

  int get _totalDuracion =>
      _servicios.where((s) => _servicioIds.contains(s.id)).fold(0, (acc, s) => acc + s.duracionMin);

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profesionalId == null || _servicioIds.isEmpty) {
      mostrarError(context, 'Elige a quién se asigna y al menos un servicio.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(schedulingRepositoryProvider).crearWalkIn(
            widget.localId,
            profesionalId: _profesionalId!,
            servicios: _servicioIds.toList(),
            inicio: _inicio,
            nombre: _nombreCtrl.text.trim(),
            telefono: _telefonoCtrl.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ahora = DateTime.now();
    final en20 = ahora.add(const Duration(minutes: 20));

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar walk-in')),
      body: _cargandoOpciones
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(mensaje: _error!, onRetry: _cargarOpciones)
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SurfaceCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const IconAvatar(icono: Icons.flash_on),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Atención en mostrador', style: Theme.of(context).textTheme.titleSmall),
                                      Text(
                                        'Turno inmediato, sin reserva previa',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Datos del cliente', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _nombreCtrl,
                            decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => AppValidators.requerido(v, 'El nombre'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _telefonoCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Celular', hintText: '09X XXX XXXX', prefixIcon: Icon(Icons.phone_iphone_outlined)),
                            validator: AppValidators.telefono,
                          ),

                          const SizedBox(height: 20),
                          Text('¿A quién se asigna?', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _profesionales.map((p) {
                              final activo = _profesionalId == p.id;
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setState(() => _profesionalId = p.id),
                                child: Container(
                                  width: 130,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: activo ? scheme.primary.withValues(alpha: 0.14) : scheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: activo ? scheme.primary : Colors.transparent),
                                  ),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: scheme.surfaceContainerHigh,
                                        backgroundImage: p.fotoUrl != null ? NetworkImage(p.fotoUrl!) : null,
                                        child: p.fotoUrl == null ? const Icon(Icons.person) : null,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        p.alias ?? p.nombre,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.labelMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: Text('Servicios a recibir', style: Theme.of(context).textTheme.headlineSmall)),
                              Text(
                                'Selección múltiple',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._servicios.map((s) {
                            final activo = _servicioIds.contains(s.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setState(() {
                                  if (activo) {
                                    _servicioIds.remove(s.id);
                                  } else {
                                    _servicioIds.add(s.id);
                                  }
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: activo ? scheme.primary.withValues(alpha: 0.12) : scheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: activo ? scheme.primary : Colors.transparent),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        activo ? Icons.check_circle : Icons.circle_outlined,
                                        color: activo ? scheme.primary : scheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.nombre, style: Theme.of(context).textTheme.titleSmall),
                                            Text(
                                              AppFormatters.duracion(s.duracionMin),
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(AppFormatters.dinero(s.precio), style: Theme.of(context).textTheme.titleSmall),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 12),
                          Text('Hora de atención', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _ChipHora(
                                  icono: Icons.play_circle_outline,
                                  texto: 'Ahora (${AppFormatters.horaLegible(ahora.toUtc())})',
                                  activo: _modoHora == _ModoHora.ahora,
                                  onTap: () => setState(() {
                                    _inicio = DateTime.now();
                                    _modoHora = _ModoHora.ahora;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ChipHora(
                                  icono: Icons.update,
                                  texto: 'En 20 min (${AppFormatters.horaLegible(en20.toUtc())})',
                                  activo: _modoHora == _ModoHora.en20,
                                  onTap: () => setState(() {
                                    _inicio = en20;
                                    _modoHora = _ModoHora.en20;
                                  }),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton.icon(
                              onPressed: _elegirHora,
                              icon: const Icon(Icons.schedule, size: 16),
                              label: Text(
                                _modoHora == _ModoHora.personalizada
                                    ? 'Hora elegida: ${AppFormatters.horaLegible(_inicio.toUtc())} · cambiar'
                                    : 'Elegir otra hora',
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          SurfaceCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Resumen de turno', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                                    Text(AppFormatters.dineroNum(_totalPrecio), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: scheme.primary)),
                                  ],
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Duración total', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                                    Text(AppFormatters.duracion(_totalDuracion), style: Theme.of(context).textTheme.titleMedium),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: 'Registrar y asignar turno',
                            icon: Icons.assignment_turned_in_outlined,
                            onPressed: _crear,
                            isLoading: _guardando,
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Se agrega instantáneamente a la agenda del día',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
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

enum _ModoHora { ahora, en20, personalizada }

class _ChipHora extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _ChipHora({required this.icono, required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: activo ? scheme.primary : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 16, color: activo ? scheme.onPrimary : scheme.onSurface),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: activo ? scheme.onPrimary : scheme.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
