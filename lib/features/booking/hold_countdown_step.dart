import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/booking_app_bar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/models/directory_models.dart';
import '../../data/models/scheduling_models.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';
import '../../state/session_controller.dart';

/// Pantalla del hold (§5.4): `reservada` con `expira_at = +10 min`, salvo
/// que el cliente tenga 3+ no-shows, en cuyo caso la cita ya nace
/// `confirmada` y no hay nada que contar.
class HoldCountdownStep extends ConsumerStatefulWidget {
  final Cita cita;

  const HoldCountdownStep({super.key, required this.cita});

  @override
  ConsumerState<HoldCountdownStep> createState() => _HoldCountdownStepState();
}

class _HoldCountdownStepState extends ConsumerState<HoldCountdownStep> {
  late Cita _cita = widget.cita;
  Timer? _timer;
  Duration _restante = Duration.zero;
  bool _confirmando = false;
  LocalPerfilPublico? _local;
  ProfesionalPerfilPublico? _profesional;

  @override
  void initState() {
    super.initState();
    if (_cita.estado == 'reservada') {
      final expira = _cita.expiraAt ?? DateTime.now().toUtc().add(ApiConfig.holdDuration);
      _actualizarRestante(expira);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _actualizarRestante(expira));
    }
    _cargarContexto();
  }

  Future<void> _cargarContexto() async {
    try {
      final local = await ref.read(directoryRepositoryProvider).perfilPublicoLocal(_cita.localId);
      if (mounted) setState(() => _local = local);
    } catch (_) {
      // No es crítico para confirmar la cita.
    }
    try {
      final perfil = await ref.read(staffingRepositoryProvider).perfilPublicoProfesional(_cita.profesionalId);
      if (mounted) setState(() => _profesional = perfil);
    } catch (_) {
      // No es crítico para confirmar la cita.
    }
  }

  void _actualizarRestante(DateTime expira) {
    final restante = expira.difference(DateTime.now().toUtc());
    if (!mounted) return;
    setState(() => _restante = restante.isNegative ? Duration.zero : restante);
    if (restante.isNegative) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _confirmar() async {
    setState(() => _confirmando = true);
    try {
      final actualizada = await ref.read(schedulingRepositoryProvider).confirmar(_cita.id);
      if (!mounted) return;
      setState(() => _cita = actualizada);
      _timer?.cancel();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _confirmando = false);
    }
  }

  String _nombreServicio(CitaItem item) {
    final match = _local?.servicios.where((s) => s.id == item.servicioLocalId);
    if (match == null || match.isEmpty) return 'Servicio';
    return match.first.nombre;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final esHold = _cita.estado == 'reservada';
    final expirado = esHold && _restante == Duration.zero;
    final avatarUrl = ref.watch(sessionControllerProvider).usuario?.fotoUrl;

    final Color colorEstado = expirado ? AppColors.peligro : (esHold ? AppColors.advertencia : AppColors.exito);
    final IconData iconoEstado = expirado ? Icons.timer_off_outlined : (esHold ? Icons.hourglass_top_outlined : Icons.check_circle_outline);
    final double progreso = esHold && !expirado
        ? (_restante.inSeconds / ApiConfig.holdDuration.inSeconds).clamp(0, 1).toDouble()
        : 1.0;

    return Scaffold(
      appBar: BookingAppBar(titulo: 'Tu reserva', mostrarAtras: false, avatarUrl: avatarUrl),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: progreso,
                        strokeWidth: 4,
                        backgroundColor: scheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation(colorEstado),
                      ),
                    ),
                    Icon(iconoEstado, size: 44, color: colorEstado),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              expirado
                  ? 'El hold expiró'
                  : esHold
                      ? '¡Horario reservado temporalmente!'
                      : '¡Cita confirmada!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              expirado
                  ? 'Vuelve a buscar un horario disponible.'
                  : esHold
                      ? 'Tu cupo está guardado mientras confirmas tu asistencia.'
                      : 'Te esperamos en la fecha y hora acordadas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _cita.codigo));
                  mostrarMensaje(context, 'Código copiado');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Código cita: ', style: Theme.of(context).textTheme.labelMedium),
                      Text(
                        '#${_cita.codigo}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.copy_outlined, size: 14, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (esHold && !expirado)
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIEMPO RESTANTE DEL HOLD',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_restante.inMinutes.toString().padLeft(2, '0')}:${(_restante.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.advertencia),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progreso,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation(AppColors.advertencia),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tienes ${ApiConfig.holdDuration.inMinutes} minutos para confirmar tu presencia y asegurar el turno.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            if (_local != null) ...[
              const SizedBox(height: 12),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_local!.nombre, style: Theme.of(context).textTheme.titleMedium),
                              Text(
                                _local!.direccion,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              if (_profesional != null)
                                Text(
                                  'Con ${_profesional!.alias ?? _profesional!.nombre}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.event_outlined, size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(child: Text(AppFormatters.fechaHoraLegible(_cita.inicio), style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._cita.items.map((i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(child: Text(_nombreServicio(i))),
                              Text(AppFormatters.dinero(i.precio)),
                            ],
                          ),
                        )),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                        Text(
                          AppFormatters.dinero(_cita.precioTotal),
                          style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (esHold && !expirado)
              PrimaryButton(label: 'Confirmar ahora', icon: Icons.check_circle_outline, onPressed: _confirmar, isLoading: _confirmando)
            else if (expirado) ...[
              FilledButton(onPressed: () => context.go('/'), child: const Text('Volver al inicio')),
            ] else ...[
              FilledButton(
                onPressed: () => context.go('/mis-citas/${_cita.id}'),
                child: const Text('Ver mi cita'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: () => context.go('/'), child: const Text('Volver al inicio')),
            ],
            const SizedBox(height: 20),
            TrustRow(items: const [(Icons.verified_user_outlined, 'Reserva protegida por FullPinta')]),
          ],
        ),
      ),
    );
  }
}
