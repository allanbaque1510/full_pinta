import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/color_dot.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/icon_text_row.dart';
import '../../core/widgets/photo_carousel.dart';
import '../../core/widgets/quick_action_button.dart';
import '../../core/widgets/star_rating.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/models/catalog_models.dart';
import '../../data/models/directory_models.dart';
import '../../state/repository_providers.dart';

class LocalPerfilPublicoScreen extends ConsumerStatefulWidget {
  final String localId;

  const LocalPerfilPublicoScreen({super.key, required this.localId});

  @override
  ConsumerState<LocalPerfilPublicoScreen> createState() => _LocalPerfilPublicoScreenState();
}

class _LocalPerfilPublicoScreenState extends ConsumerState<LocalPerfilPublicoScreen> {
  LocalPerfilPublico? _local;
  bool _cargando = true;
  String? _error;

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
      final local = await ref.read(directoryRepositoryProvider).perfilPublicoLocal(widget.localId);
      if (!mounted) return;
      setState(() => _local = local);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _local == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(mensaje: _error ?? 'No se pudo cargar el local.', onRetry: _cargar),
      );
    }

    final local = _local!;
    final scheme = Theme.of(context).colorScheme;
    final abiertoAhora = _abiertoAhora(local.horarios);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            actions: [
              FavoriteButton(localId: widget.localId, esFavoritoInicial: local.esFavorito),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: PhotoCarousel(urls: local.fotos.map((f) => f.url).toList()),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (local.verificado)
                        StatusBadge(icono: Icons.verified, texto: 'Verificado FullPinta', color: scheme.primary),
                      StatusBadge(
                        icono: abiertoAhora ? Icons.radio_button_checked : Icons.schedule,
                        texto: abiertoAhora ? 'Abierto ahora' : 'Cerrado ahora',
                        color: abiertoAhora ? scheme.tertiary : scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(local.nombre, style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StarRatingView(puntaje: local.resenas.promedio, tamano: 18),
                      const SizedBox(width: 6),
                      Text(
                        local.resenas.total > 0
                            ? '${local.resenas.promedio.toStringAsFixed(1)} (${local.resenas.total} reseñas)'
                            : 'Nuevo en la plataforma',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  IconTextRow(icono: Icons.place_outlined, texto: local.direccion),
                  if (local.referencia != null && local.referencia!.isNotEmpty)
                    IconTextRow(icono: Icons.info_outline, texto: local.referencia!),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (local.whatsapp != null)
                        Expanded(
                          child: QuickActionButton(
                            icono: Icons.chat_outlined,
                            etiqueta: 'WhatsApp',
                            color: scheme.tertiary,
                            onTap: () => launchUrl(
                              Uri.parse('https://wa.me/593${local.whatsapp!.replaceFirst(RegExp(r'^0'), '')}'),
                            ),
                          ),
                        ),
                      if (local.telefono != null)
                        Expanded(
                          child: QuickActionButton(
                            icono: Icons.call_outlined,
                            etiqueta: 'Llamar',
                            color: scheme.secondary,
                            onTap: () => launchUrl(Uri.parse('tel:${local.telefono}')),
                          ),
                        ),
                      Expanded(
                        child: QuickActionButton(
                          icono: Icons.directions_outlined,
                          etiqueta: 'Llegar',
                          color: scheme.primary,
                          onTap: () => launchUrl(
                            Uri.parse('https://www.google.com/maps/search/?api=1&query=${local.lat},${local.lng}'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text('Servicios', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  ...local.servicios.where((s) => s.activo).map((s) => _ServicioCard(servicio: s)),
                  if (local.amenidades.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text('Amenidades', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: local.amenidades.map((a) => Chip(label: Text(a.nombre))).toList(),
                    ),
                  ],
                  const Divider(height: 32),
                  Row(
                    children: [
                      Text('Horarios', style: Theme.of(context).textTheme.headlineSmall),
                      const Spacer(),
                      StatusBadge(
                        icono: abiertoAhora ? Icons.radio_button_checked : Icons.schedule,
                        texto: abiertoAhora ? 'Abierto ahora' : 'Cerrado ahora',
                        color: abiertoAhora ? scheme.tertiary : scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SurfaceCard(child: Column(children: _agruparHorarios(local.horarios))),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: local.servicios.where((s) => s.activo).isEmpty
            ? null
            : () => context.push('/local/${local.id}/agendar', extra: local),
        icon: const Icon(Icons.calendar_month_outlined),
        label: const Text('Agendar'),
      ),
    );
  }

  /// Comparación simple contra el horario del día (hora de Guayaquil, §4.2)
  /// — mismo criterio que `abierto_ahora` en `GET /buscar/locales`, pero
  /// calculado acá para pintar el badge sin otra llamada a la API.
  bool _abiertoAhora(List<HorarioLocal> horarios) {
    final ahora = AppFormatters.aGuayaquil(DateTime.now().toUtc());
    final minutosAhora = ahora.hour * 60 + ahora.minute;
    for (final h in horarios.where((h) => h.diaSemana == ahora.weekday % 7)) {
      final abre = _minutos(h.abre);
      final cierra = _minutos(h.cierra);
      if (minutosAhora >= abre && minutosAhora < cierra) return true;
    }
    return false;
  }

  int _minutos(String horaHHmm) {
    final partes = horaHHmm.split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }

  List<Widget> _agruparHorarios(List<HorarioLocal> horarios) {
    final porDia = <int, List<HorarioLocal>>{};
    for (final h in horarios) {
      porDia.putIfAbsent(h.diaSemana, () => []).add(h);
    }
    final scheme = Theme.of(context).colorScheme;
    final hoyIndice = AppFormatters.aGuayaquil(DateTime.now().toUtc()).weekday % 7;
    return List.generate(7, (dia) {
      final filas = porDia[dia];
      final cerrado = filas == null || filas.isEmpty;
      final esHoy = dia == hoyIndice;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 14, child: esHoy ? ColorDot(color: scheme.primary) : null),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: Text(
                nombresDias[dia],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: esHoy ? FontWeight.w700 : FontWeight.w400,
                      color: esHoy ? scheme.onSurface : scheme.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                cerrado ? 'Cerrado' : filas.map((f) => '${f.abre} - ${f.cierra}').join('  ·  '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cerrado ? scheme.onSurfaceVariant : scheme.onSurface,
                      fontWeight: esHoy ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ServicioCard extends StatelessWidget {
  final ServicioLocal servicio;

  const _ServicioCard({required this.servicio});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(servicio.nombre, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${servicio.precioDesde ? 'Desde ' : ''}${AppFormatters.dinero(servicio.precio)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 13, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text(AppFormatters.duracion(servicio.duracionMin), style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
