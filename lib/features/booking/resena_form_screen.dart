import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/icon_text_row.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/star_rating.dart';
import '../../core/widgets/surface_card.dart';
import '../../core/widgets/tag_pill.dart';
import '../../data/models/directory_models.dart';
import '../../data/models/scheduling_models.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

const _etiquetasPuntaje = {0: 'Sin calificar', 1: 'Malo', 2: 'Regular', 3: 'Bien', 4: 'Muy bien', 5: 'Excelente'};

/// Reseña post-cita (§4.8): solo `completada`, ventana de 14 días, una por
/// cita — todo lo valida el backend; acá solo se arma el formulario.
class ResenaFormScreen extends ConsumerStatefulWidget {
  final Cita cita;

  const ResenaFormScreen({super.key, required this.cita});

  @override
  ConsumerState<ResenaFormScreen> createState() => _ResenaFormScreenState();
}

class _ResenaFormScreenState extends ConsumerState<ResenaFormScreen> {
  int _puntajeLocal = 0;
  int _puntajeProfesional = 0;
  int _puntualidad = 0;
  int _limpieza = 0;
  final _comentarioCtrl = TextEditingController();
  bool _enviando = false;

  LocalPerfilPublico? _local;
  ProfesionalPerfilPublico? _profesional;

  @override
  void initState() {
    super.initState();
    _cargarContexto();
    _comentarioCtrl.addListener(() => setState(() {}));
  }

  Future<void> _cargarContexto() async {
    try {
      final local = await ref.read(directoryRepositoryProvider).perfilPublicoLocal(widget.cita.localId);
      if (mounted) setState(() => _local = local);
    } catch (_) {}
    try {
      final profesional = await ref.read(staffingRepositoryProvider).perfilPublicoProfesional(widget.cita.profesionalId);
      if (mounted) setState(() => _profesional = profesional);
    } catch (_) {}
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  String get _nombreServicios {
    final servicios = _local?.servicios;
    if (servicios == null || widget.cita.items.isEmpty) return '';
    return widget.cita.items
        .map((i) {
          final match = servicios.where((s) => s.id == i.servicioLocalId);
          return match.isEmpty ? 'Servicio' : match.first.nombre;
        })
        .join(' + ');
  }

  Future<void> _enviar() async {
    if (_puntajeLocal == 0) {
      mostrarError(context, 'Califica al menos "El local" para poder enviar tu reseña.');
      return;
    }
    setState(() => _enviando = true);
    try {
      await ref.read(reviewsRepositoryProvider).crearResena(
            widget.cita.id,
            puntajeLocal: _puntajeLocal,
            puntajeProfesional: _puntajeProfesional == 0 ? null : _puntajeProfesional,
            puntualidad: _puntualidad == 0 ? null : _puntualidad,
            limpieza: _limpieza == 0 ? null : _limpieza,
            comentario: _comentarioCtrl.text.trim().isEmpty ? null : _comentarioCtrl.text.trim(),
          );
      if (!mounted) return;
      mostrarMensaje(context, '¡Gracias por tu reseña!');
      context.pop();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final servicios = _nombreServicios;

    return Scaffold(
      appBar: AppBar(title: const Text('Dejar una reseña')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Resumen de la cita ----
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TagPill(texto: 'Servicio completado', color: scheme.tertiary),
                    const Spacer(),
                    Text('#${widget.cita.codigo}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_local?.nombre ?? 'Local', style: Theme.of(context).textTheme.headlineSmall),
                if (_profesional != null)
                  IconTextRow(icono: Icons.person_outline, texto: _profesional!.alias ?? _profesional!.nombre),
                if (servicios.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.content_cut, size: 15, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(child: Text(servicios, style: Theme.of(context).textTheme.bodySmall)),
                      Text(AppFormatters.dinero(widget.cita.precioTotal), style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                ],
                IconTextRow(icono: Icons.event_outlined, texto: AppFormatters.fechaHoraLegible(widget.cita.inicio)),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('Califica tu experiencia', style: Theme.of(context).textTheme.headlineSmall),
          Text(
            'Toca las estrellas para compartir tu valoración real',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          _CampoEstrellas(
            icono: Icons.storefront_outlined,
            titulo: 'Local en general',
            subtitulo: '¿Cómo fue tu experiencia global en el local?',
            valor: _puntajeLocal,
            onChanged: (v) => setState(() => _puntajeLocal = v),
          ),
          _CampoEstrellas(
            icono: Icons.person_outline,
            titulo: _profesional != null ? 'Profesional (${_profesional!.alias ?? _profesional!.nombre})' : 'Profesional',
            subtitulo: 'Calidad de la atención y la técnica',
            valor: _puntajeProfesional,
            onChanged: (v) => setState(() => _puntajeProfesional = v),
          ),
          _CampoEstrellas(
            icono: Icons.schedule,
            titulo: 'Puntualidad',
            subtitulo: '¿Te atendieron a la hora agendada?',
            valor: _puntualidad,
            onChanged: (v) => setState(() => _puntualidad = v),
          ),
          _CampoEstrellas(
            icono: Icons.cleaning_services_outlined,
            titulo: 'Limpieza e higiene',
            subtitulo: 'Protocolo de toallas, sillón y orden',
            valor: _limpieza,
            onChanged: (v) => setState(() => _limpieza = v),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('Comentario o recomendación (opcional)', style: Theme.of(context).textTheme.titleSmall)),
              Text(
                '${_comentarioCtrl.text.length}/500',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 4,
            maxLength: 500,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            decoration: const InputDecoration(hintText: 'Cuéntale a otros clientes cómo te fue...'),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Publicar reseña', icon: Icons.rate_review_outlined, onPressed: _enviar, isLoading: _enviando),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tu reseña ayuda a que otros clientes elijan con confianza.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoEstrellas extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final int valor;
  final ValueChanged<int> onChanged;

  const _CampoEstrellas({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: Theme.of(context).textTheme.titleSmall),
                    Text(subtitulo, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (valor > 0) TagPill(texto: '$valor/5 · ${_etiquetasPuntaje[valor]}', color: scheme.primary),
            ],
          ),
          const SizedBox(height: 6),
          Center(child: StarRatingInput(valor: valor, onChanged: onChanged, tamano: 28)),
        ],
      ),
    );
  }
}
