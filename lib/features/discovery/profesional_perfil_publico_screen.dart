import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/gradient_ring_avatar.dart';
import '../../core/widgets/icon_avatar.dart';
import '../../core/widgets/star_rating.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

class ProfesionalPerfilPublicoScreen extends ConsumerStatefulWidget {
  final String profesionalId;

  const ProfesionalPerfilPublicoScreen({super.key, required this.profesionalId});

  @override
  ConsumerState<ProfesionalPerfilPublicoScreen> createState() => _ProfesionalPerfilPublicoScreenState();
}

class _ProfesionalPerfilPublicoScreenState extends ConsumerState<ProfesionalPerfilPublicoScreen> {
  ProfesionalPerfilPublico? _perfil;
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
      final perfil = await ref.read(staffingRepositoryProvider).perfilPublicoProfesional(widget.profesionalId);
      if (!mounted) return;
      setState(() => _perfil = perfil);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _perfil == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(mensaje: _error ?? 'No se pudo cargar el perfil.', onRetry: _cargar),
      );
    }

    final p = _perfil!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil profesional'),
        actions: [FavoriteButton(profesionalId: widget.profesionalId, esFavoritoInicial: p.esFavorito)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: GradientRingAvatar(url: p.fotoUrl, radio: 48)),
          const SizedBox(height: 14),
          Text(p.nombre, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
          if (p.alias != null && p.alias!.isNotEmpty)
            Text(
              '"${p.alias}"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StarRatingView(puntaje: p.resenas.promedio, tamano: 18),
                const SizedBox(width: 6),
                Text(
                  p.resenas.total > 0
                      ? '${p.resenas.promedio.toStringAsFixed(1)} (${p.resenas.total} reseñas)'
                      : 'Nuevo en la plataforma',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          if (p.bio != null && p.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(p.bio!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (p.fotos.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Trabajos destacados', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                Text('${p.fotos.length} fotos', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: p.fotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: p.fotos[i].url,
                    width: 120,
                    height: 160,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(width: 120, color: scheme.surfaceContainerHigh),
                    errorWidget: (context, url, error) => Container(
                      width: 120,
                      color: scheme.surfaceContainerHigh,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (p.servicios.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Especialidades y servicios', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                Text(
                  '${p.servicios.length} servicios',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...p.servicios.map((s) => Card(
                  child: ListTile(
                    leading: const IconAvatar(icono: Icons.content_cut, tamanoIcono: 18),
                    title: Text(s.servicioNombre),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
