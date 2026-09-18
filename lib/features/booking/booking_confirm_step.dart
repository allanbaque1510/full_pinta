import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/booking_app_bar.dart';
import '../../core/widgets/booking_step_indicator.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/photo_carousel.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/models/scheduling_models.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';
import '../../state/session_controller.dart';
import 'booking_draft.dart';

class BookingConfirmStep extends ConsumerStatefulWidget {
  final BookingDraft draft;
  final VoidCallback onAtras;
  final ValueChanged<Cita> onCitaCreada;

  const BookingConfirmStep({
    super.key,
    required this.draft,
    required this.onAtras,
    required this.onCitaCreada,
  });

  @override
  ConsumerState<BookingConfirmStep> createState() => _BookingConfirmStepState();
}

class _BookingConfirmStepState extends ConsumerState<BookingConfirmStep> {
  final _notaCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  String _paraTipo = 'titular';
  bool _enviando = false;
  ProfesionalPerfilPublico? _profesional;

  @override
  void initState() {
    super.initState();
    _cargarProfesional();
  }

  Future<void> _cargarProfesional() async {
    final slot = widget.draft.slot;
    if (slot == null) return;
    try {
      final perfil = await ref.read(staffingRepositoryProvider).perfilPublicoProfesional(slot.profesionalId);
      if (mounted) setState(() => _profesional = perfil);
    } catch (_) {
      // No es crítico para poder reservar.
    }
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final slot = widget.draft.slot;
    if (slot == null) return;
    if (_paraTipo == 'otra_persona' && _nombreCtrl.text.trim().isEmpty) {
      mostrarError(context, 'Indica el nombre de la persona.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final cita = await ref.read(schedulingRepositoryProvider).crearCita(
            widget.draft.local.id,
            profesionalId: slot.profesionalId,
            servicios: widget.draft.servicioIds.toList(),
            inicio: slot.inicio,
            recursoId: slot.recursoId,
            paraTipo: _paraTipo,
            paraNombre: _paraTipo == 'otra_persona' ? _nombreCtrl.text.trim() : null,
            notaCliente: _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
          );
      widget.onCitaCreada(cita);
    } catch (e) {
      if (!mounted) return;
      final error = DioClient.mapearError(e);
      if (error.esConflicto) {
        mostrarError(context, 'Ese horario se acaba de ocupar. Elige otro.');
        widget.onAtras();
      } else {
        mostrarError(context, error.mensaje);
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slot = widget.draft.slot!;
    final local = widget.draft.local;
    final servicios = local.servicios.where((s) => widget.draft.servicioIds.contains(s.id));
    final avatarUrl = ref.watch(sessionControllerProvider).usuario?.fotoUrl;
    final nombreCliente = ref.watch(sessionControllerProvider).usuario?.nombre.split(' ').first;

    return Scaffold(
      appBar: BookingAppBar(titulo: 'Confirmar reserva', onAtras: widget.onAtras, avatarUrl: avatarUrl),
      body: Column(
        children: [
          const BookingStepIndicator(paso: 3, total: 4, etiqueta: 'Revisión previa'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (local.verificado)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: StatusBadge(icono: Icons.verified_outlined, texto: 'Local verificado', color: scheme.tertiary),
                                  ),
                                Text(local.nombre, style: Theme.of(context).textTheme.titleMedium),
                                Text(
                                  local.direccion,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          if (local.fotos.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(imageUrl: local.fotos.first.url, width: 48, height: 48, fit: BoxFit.cover),
                            ),
                          ],
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(Icons.event_outlined, size: 18, color: scheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FECHA Y HORA',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                                Text(AppFormatters.fechaHoraLegible(slot.inicio), style: Theme.of(context).textTheme.titleSmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_profesional != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            NetworkAvatar(url: _profesional!.fotoUrl, radio: 16),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PROFESIONAL ASIGNADO',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                                Text(_profesional!.alias ?? _profesional!.nombre, style: Theme.of(context).textTheme.titleSmall),
                              ],
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      Text(
                        'SERVICIOS SELECCIONADOS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      ...servicios.map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.nombre, style: Theme.of(context).textTheme.bodyMedium),
                                      Text(
                                        AppFormatters.duracion(s.duracionMin),
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(AppFormatters.dinero(s.precio)),
                              ],
                            ),
                          )),
                      const SizedBox(height: 8),
                      SurfaceCard(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(12),
                        radio: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(child: Text('Total a pagar en el local', style: TextStyle(fontWeight: FontWeight.w600))),
                                Text(
                                  AppFormatters.dineroNum(widget.draft.precioTotal),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary),
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('¿Para quién es la cita?', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(nombreCliente != null ? 'Para mí ($nombreCliente)' : 'Para mí'),
                        selected: _paraTipo == 'titular',
                        onSelected: (_) => setState(() => _paraTipo = 'titular'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Para otra persona'),
                        selected: _paraTipo == 'otra_persona',
                        onSelected: (_) => setState(() => _paraTipo = 'otra_persona'),
                      ),
                    ),
                  ],
                ),
                if (_paraTipo == 'otra_persona') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre completo de la persona'),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _notaCtrl,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Nota o preferencia especial (opcional)',
                    hintText: 'Ej. "fade 2 a los lados, tijera arriba"',
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(label: 'Reservar cita', icon: Icons.arrow_forward, onPressed: _confirmar, isLoading: _enviando),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
