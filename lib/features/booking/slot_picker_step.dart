import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/booking_app_bar.dart';
import '../../core/widgets/booking_date_strip.dart';
import '../../core/widgets/booking_step_indicator.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/photo_carousel.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/star_rating.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/models/scheduling_models.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';
import '../../state/session_controller.dart';
import 'booking_draft.dart';
import 'espera_dialog.dart';

class SlotPickerStep extends ConsumerStatefulWidget {
  final BookingDraft draft;
  final VoidCallback onAtras;
  final ValueChanged<SlotDisponible> onSlotElegido;
  final bool mostrarProgreso;

  const SlotPickerStep({
    super.key,
    required this.draft,
    required this.onAtras,
    required this.onSlotElegido,
    this.mostrarProgreso = true,
  });

  @override
  ConsumerState<SlotPickerStep> createState() => _SlotPickerStepState();
}

class _SlotPickerStepState extends ConsumerState<SlotPickerStep> {
  bool _cargando = true;
  String? _error;
  Map<String, List<SlotDisponible>> _slotsPorProfesional = {};
  final Map<String, ProfesionalPerfilPublico?> _perfiles = {};
  SlotDisponible? _slotSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
      _slotSeleccionado = null;
    });
    if (widget.draft.servicioIds.isEmpty) {
      setState(() {
        _error = 'No hay servicios seleccionados para buscar horarios.';
        _cargando = false;
      });
      return;
    }
    try {
      final repo = ref.read(schedulingRepositoryProvider);
      final slots = await repo.disponibilidad(
        widget.draft.local.id,
        fecha: AppFormatters.fechaIso(widget.draft.fecha),
        servicioLocalIds: widget.draft.servicioIds.toList(),
      );

      final agrupados = <String, List<SlotDisponible>>{};
      for (final s in slots) {
        agrupados.putIfAbsent(s.profesionalId, () => []).add(s);
      }

      final staffing = ref.read(staffingRepositoryProvider);
      for (final profesionalId in agrupados.keys) {
        if (_perfiles.containsKey(profesionalId)) continue;
        try {
          _perfiles[profesionalId] = await staffing.perfilPublicoProfesional(profesionalId);
        } catch (_) {
          _perfiles[profesionalId] = null;
        }
      }

      if (!mounted) return;
      setState(() => _slotsPorProfesional = agrupados);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarFecha(DateTime fecha) async {
    widget.draft.fecha = fecha;
    await _cargar();
  }

  Future<void> _anotarseEnEspera() async {
    final resultado = await mostrarEsperaDialog(
      context,
      localId: widget.draft.local.id,
      servicioLocalId: widget.draft.servicioIds.first,
      fechaDeseada: AppFormatters.fechaIso(widget.draft.fecha),
    );
    if (resultado == true && mounted) {
      mostrarMensaje(context, 'Te anotamos en la lista de espera para ese día.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarUrl = ref.watch(sessionControllerProvider).usuario?.fotoUrl;

    return Scaffold(
      appBar: BookingAppBar(titulo: 'Elige tu horario', onAtras: widget.onAtras, avatarUrl: avatarUrl),
      body: Column(
        children: [
          if (widget.mostrarProgreso) const BookingStepIndicator(paso: 2, total: 4, etiqueta: 'Elige tu horario ideal'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppFormatters.fechaLegible(widget.draft.fecha.toUtc()), style: Theme.of(context).textTheme.titleSmall),
                            Text(
                              '${widget.draft.local.nombre} · ${widget.draft.servicioIds.length} ${widget.draft.servicioIds.length == 1 ? 'servicio' : 'servicios'} (${AppFormatters.duracion(widget.draft.duracionTotalMin)})',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onAtras,
                        icon: const Icon(Icons.edit_calendar_outlined),
                        tooltip: 'Cambiar servicios o fecha',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                BookingDateStrip(
                  seleccionada: widget.draft.fecha,
                  diasVisibles: widget.draft.local.horizonteDias.clamp(1, 21),
                  onSeleccionar: _cambiarFecha,
                ),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorState(mensaje: _error!, onRetry: _cargar)
                    : _slotsPorProfesional.isEmpty
                        ? EmptyState(
                            mensaje: 'No hay horarios disponibles ese día para lo que elegiste.',
                            icono: Icons.event_busy_outlined,
                            accion: OutlinedButton.icon(
                              onPressed: _anotarseEnEspera,
                              icon: const Icon(Icons.notifications_active_outlined),
                              label: const Text('Anotarme en lista de espera'),
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, _slotSeleccionado != null ? 16 : 100),
                            children: [
                              ..._slotsPorProfesional.entries.map((entry) {
                                final slots = entry.value..sort((a, b) => a.inicio.compareTo(b.inicio));
                                final perfil = _perfiles[entry.key];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: SurfaceCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            NetworkAvatar(url: perfil?.fotoUrl, radio: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    perfil?.alias ?? perfil?.nombre ?? 'Profesional disponible',
                                                    style: Theme.of(context).textTheme.titleSmall,
                                                  ),
                                                  if (perfil?.bio != null && perfil!.bio!.isNotEmpty)
                                                    Text(
                                                      perfil.bio!,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            if (perfil != null && perfil.resenas.total > 0) ...[
                                              StarRatingView(puntaje: perfil.resenas.promedio, tamano: 13),
                                              const SizedBox(width: 4),
                                              Text(
                                                perfil.resenas.promedio.toStringAsFixed(1),
                                                style: Theme.of(context).textTheme.labelSmall,
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: slots.map((s) {
                                            final activo = _slotSeleccionado == s;
                                            return ChoiceChip(
                                              label: Text(AppFormatters.horaLegible(s.inicio)),
                                              selected: activo,
                                              onSelected: (_) => setState(() => _slotSeleccionado = s),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              SurfaceCard(
                                child: Row(
                                  children: [
                                    Icon(Icons.notifications_active_outlined, color: scheme.secondary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('¿No encuentras tu hora ideal?', style: Theme.of(context).textTheme.titleSmall),
                                          Text(
                                            'Anótate en la lista de espera y te avisamos si se libera un cupo.',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(onPressed: _anotarseEnEspera, child: const Text('Anotarme')),
                                  ],
                                ),
                              ),
                            ],
                          ),
          ),
          if (_slotSeleccionado != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TURNO SELECCIONADO',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          Text(
                            '${AppFormatters.fechaCorta(_slotSeleccionado!.inicio)} · ${AppFormatters.horaLegible(_slotSeleccionado!.inicio)}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    PrimaryButton(
                      label: 'Continuar',
                      icon: Icons.arrow_forward,
                      onPressed: () => widget.onSlotElegido(_slotSeleccionado!),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
