import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/estado_cita_pill.dart';
import '../../core/widgets/photo_carousel.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/quick_action_button.dart';
import '../../core/widgets/star_rating.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/models/directory_models.dart';
import '../../data/models/scheduling_models.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

class CitaDetalleScreen extends ConsumerStatefulWidget {
  final String citaId;

  const CitaDetalleScreen({super.key, required this.citaId});

  @override
  ConsumerState<CitaDetalleScreen> createState() => _CitaDetalleScreenState();
}

class _CitaDetalleScreenState extends ConsumerState<CitaDetalleScreen> {
  Cita? _cita;
  LocalPerfilPublico? _local;
  ProfesionalPerfilPublico? _profesional;
  bool _cargando = true;
  String? _error;
  bool _procesando = false;

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
      final cita = await ref.read(schedulingRepositoryProvider).obtenerCita(widget.citaId);
      if (!mounted) return;
      setState(() => _cita = cita);

      Future<LocalPerfilPublico?> cargarLocal() async {
        try {
          return await ref.read(directoryRepositoryProvider).perfilPublicoLocal(cita.localId);
        } catch (_) {
          return null;
        }
      }

      Future<ProfesionalPerfilPublico?> cargarProfesional() async {
        try {
          return await ref.read(staffingRepositoryProvider).perfilPublicoProfesional(cita.profesionalId);
        } catch (_) {
          return null;
        }
      }

      final localFuture = cargarLocal();
      final profesionalFuture = cargarProfesional();
      final local = await localFuture;
      final profesional = await profesionalFuture;
      if (!mounted) return;
      setState(() {
        _local = local;
        _profesional = profesional;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _confirmar() async {
    await _ejecutar(() => ref.read(schedulingRepositoryProvider).confirmar(widget.citaId));
  }

  Future<void> _cancelar() async {
    final ok = await confirmarDialogo(
      context,
      titulo: 'Cancelar cita',
      mensaje: '¿Seguro que quieres cancelar esta cita?',
      textoConfirmar: 'Sí, cancelar',
      textoCancelar: 'Volver',
      destructivo: true,
    );
    if (!ok) return;
    await _ejecutar(() => ref.read(schedulingRepositoryProvider).cancelar(widget.citaId));
  }

  Future<void> _ejecutar(Future<Cita> Function() accion) async {
    setState(() => _procesando = true);
    try {
      final actualizada = await accion();
      if (mounted) setState(() => _cita = actualizada);
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  /// `CitaItem` no trae el nombre del servicio (ver `docs/frontend-flutter.md`,
  /// notas para el backend) — se resuelve cruzando contra los servicios del
  /// perfil público del local, que ya se cargó para esta misma pantalla.
  String _nombreServicio(CitaItem item) {
    final match = _local?.servicios.where((s) => s.id == item.servicioLocalId);
    if (match == null || match.isEmpty) return 'Servicio';
    return match.first.nombre;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _cita == null) {
      return Scaffold(appBar: AppBar(), body: ErrorState(mensaje: _error ?? 'No se pudo cargar.', onRetry: _cargar));
    }

    final cita = _cita!;
    final scheme = Theme.of(context).colorScheme;
    final color = colorEstadoCita(cita.estado);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de cita')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Estado + código ----
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EstadoCitaPill(estado: cita.estado),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: cita.codigo));
                        mostrarMensaje(context, 'Código copiado');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('#${cita.codigo}', style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(width: 4),
                          Icon(Icons.copy_outlined, size: 14, color: scheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Cita agendada', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(text: '${AppFormatters.fechaHoraLegible(cita.inicio)} '),
                            TextSpan(
                              text: '(${AppFormatters.tiempoRelativo(cita.inicio)})',
                              style: TextStyle(color: color, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (cita.estado == 'reservada' && cita.expiraAt != null) ...[
                  const SizedBox(height: 10),
                  SurfaceCard(
                    padding: const EdgeInsets.all(10),
                    radio: 10,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Confirma tu presencia antes de las ${AppFormatters.horaLegible(cita.expiraAt!)} o el horario se libera.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ---- Local ----
          if (_local != null) ...[
            const SizedBox(height: 12),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BARBERÍA SELECCIONADA', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.primary)),
                  const SizedBox(height: 4),
                  Text(_local!.nombre, style: Theme.of(context).textTheme.headlineSmall),
                  Text(
                    _local!.direccion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_local!.telefono != null)
                        Expanded(
                          child: QuickActionButton(
                            icono: Icons.call_outlined,
                            etiqueta: 'Llamar',
                            onTap: () => launchUrl(Uri.parse('tel:${_local!.telefono}')),
                          ),
                        ),
                      if (_local!.whatsapp != null)
                        Expanded(
                          child: QuickActionButton(
                            icono: Icons.chat_outlined,
                            etiqueta: 'WhatsApp',
                            onTap: () => launchUrl(
                              Uri.parse('https://wa.me/593${_local!.whatsapp!.replaceFirst(RegExp(r'^0'), '')}'),
                            ),
                          ),
                        ),
                      Expanded(
                        child: QuickActionButton(
                          icono: Icons.directions_outlined,
                          etiqueta: 'Cómo llegar',
                          onTap: () => launchUrl(
                            Uri.parse('https://www.google.com/maps/search/?api=1&query=${_local!.lat},${_local!.lng}'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ---- Profesional ----
          if (_profesional != null) ...[
            const SizedBox(height: 12),
            SurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  NetworkAvatar(url: _profesional!.fotoUrl, radio: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_profesional!.alias ?? _profesional!.nombre, style: Theme.of(context).textTheme.titleMedium),
                        Row(
                          children: [
                            StarRatingView(puntaje: _profesional!.resenas.promedio, tamano: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${_profesional!.resenas.promedio.toStringAsFixed(1)} (${_profesional!.resenas.total})',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ---- Servicios ----
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Servicios agendados', style: Theme.of(context).textTheme.headlineSmall)),
                    Text(
                      cita.items.length == 1 ? '1 item' : '${cita.items.length} items',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...cita.items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_nombreServicio(i), style: Theme.of(context).textTheme.titleSmall),
                                Text(
                                  AppFormatters.duracion(i.duracionMin),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Text(AppFormatters.dinero(i.precio), style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                    )),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(child: Text('Total a pagar', style: Theme.of(context).textTheme.titleMedium)),
                    Text(
                      AppFormatters.dinero(cita.precioTotal),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: scheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pago en efectivo, transferencia o tarjeta directo en el local — FullPinta no cobra nada por la reserva.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          if (cita.notaCliente != null && cita.notaCliente!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sticky_note_2_outlined, size: 16, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text('Tu nota para el local', style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('"${cita.notaCliente}"', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          if (cita.estado == 'reservada')
            PrimaryButton(
              label: 'Confirmar mi asistencia',
              icon: Icons.check_circle_outline,
              onPressed: _confirmar,
              isLoading: _procesando,
            ),
          if (cita.estado == 'reservada' || cita.estado == 'confirmada') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _procesando ? null : () => context.push('/mis-citas/${cita.id}/reagendar', extra: cita),
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label: const Text('Reagendar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _procesando ? null : _cancelar,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.peligro),
                  ),
                ),
              ],
            ),
          ],
          if (cita.estado == 'completada') ...[
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Dejar reseña',
              icon: Icons.star_outline,
              onPressed: () => context.push('/mis-citas/${cita.id}/resena', extra: cita),
            ),
          ],
        ],
      ),
    );
  }
}
