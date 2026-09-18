import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/booking_app_bar.dart';
import '../../core/widgets/booking_date_strip.dart';
import '../../core/widgets/booking_step_indicator.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/surface_card.dart';
import '../../core/widgets/tag_pill.dart';
import '../../state/session_controller.dart';
import 'booking_draft.dart';

class SeleccionServiciosStep extends ConsumerStatefulWidget {
  final BookingDraft draft;
  final VoidCallback onContinuar;

  const SeleccionServiciosStep({super.key, required this.draft, required this.onContinuar});

  @override
  ConsumerState<SeleccionServiciosStep> createState() => _SeleccionServiciosStepState();
}

class _SeleccionServiciosStepState extends ConsumerState<SeleccionServiciosStep> {
  Future<void> _elegirFechaEnCalendario() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: widget.draft.fecha.isBefore(hoy) ? hoy : widget.draft.fecha,
      firstDate: hoy,
      lastDate: hoy.add(Duration(days: widget.draft.local.horizonteDias)),
    );
    if (elegida != null) setState(() => widget.draft.fecha = elegida);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final local = widget.draft.local;
    final servicios = local.servicios.where((s) => s.activo).toList();
    final avatarUrl = ref.watch(sessionControllerProvider).usuario?.fotoUrl;
    final hoy = DateTime.now();
    final esHoy = widget.draft.fecha.year == hoy.year && widget.draft.fecha.month == hoy.month && widget.draft.fecha.day == hoy.day;

    return Scaffold(
      appBar: BookingAppBar(titulo: 'Servicios y fecha', avatarUrl: avatarUrl),
      body: Column(
        children: [
          const BookingStepIndicator(paso: 1, total: 4, etiqueta: 'Servicios y Fecha'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                SurfaceCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: scheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    local.direccion,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(local.nombre, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (local.verificado)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: StatusBadge(icono: Icons.verified_outlined, texto: 'Verificado', color: scheme.tertiary),
                                  ),
                                if (local.resenas.total > 0)
                                  Text(
                                    '★ ${local.resenas.promedio.toStringAsFixed(1)} (${local.resenas.total})',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (local.fotos.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: local.fotos.first.url,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text('Seleccionar fecha', style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _elegirFechaEnCalendario,
                      icon: const Icon(Icons.expand_more, size: 16),
                      label: const Text('Mes completo'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.event_outlined, size: 18, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FECHA DE LA CITA',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            Text(AppFormatters.fechaLegible(widget.draft.fecha.toUtc()), style: Theme.of(context).textTheme.titleSmall),
                          ],
                        ),
                      ),
                      if (esHoy) TagPill(texto: 'Hoy', color: scheme.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                BookingDateStrip(
                  seleccionada: widget.draft.fecha,
                  diasVisibles: local.horizonteDias.clamp(1, 21),
                  onSeleccionar: (fecha) => setState(() => widget.draft.fecha = fecha),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.content_cut, size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text('Servicios del local', style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    Text(
                      'Elige uno o varios',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...servicios.map((s) {
                  final elegido = widget.draft.servicioIds.contains(s.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() {
                        if (elegido) {
                          widget.draft.servicioIds.remove(s.id);
                        } else {
                          widget.draft.servicioIds.add(s.id);
                        }
                      }),
                      child: SurfaceCard(
                        margin: EdgeInsets.zero,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IgnorePointer(
                              child: Checkbox(value: elegido, onChanged: (_) {}),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.nombre, style: Theme.of(context).textTheme.titleSmall),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule, size: 13, color: scheme.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppFormatters.duracion(s.duracionMin),
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.dinero(s.precio),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.draft.servicioIds.isNotEmpty)
                          Text(
                            '${widget.draft.servicioIds.length} ${widget.draft.servicioIds.length == 1 ? 'servicio' : 'servicios'} · ${AppFormatters.duracion(widget.draft.duracionTotalMin)}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        Text(
                          'Total: ${AppFormatters.dineroNum(widget.draft.precioTotal)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  PrimaryButton(
                    label: 'Ver horarios',
                    icon: Icons.arrow_forward,
                    onPressed: widget.draft.servicioIds.isEmpty
                        ? null
                        : () {
                            if (widget.draft.servicioIds.isEmpty) {
                              mostrarError(context, 'Elige al menos un servicio.');
                              return;
                            }
                            widget.onContinuar();
                          },
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
