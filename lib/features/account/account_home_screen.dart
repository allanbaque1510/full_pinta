import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_ring_avatar.dart';
import '../../core/widgets/icon_avatar.dart';
import '../../core/widgets/icon_text_row.dart';
import '../../core/widgets/menu_access_tile.dart';
import '../../core/widgets/surface_card.dart';
import '../../core/widgets/tag_pill.dart';
import '../../data/models/identity_models.dart';
import '../../state/repository_providers.dart';
import '../../state/session_controller.dart';

class AccountHomeScreen extends ConsumerStatefulWidget {
  const AccountHomeScreen({super.key});

  @override
  ConsumerState<AccountHomeScreen> createState() => _AccountHomeScreenState();
}

class _AccountHomeScreenState extends ConsumerState<AccountHomeScreen> {
  int? _totalFavoritos;

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    try {
      final favoritos = await ref.read(identityRepositoryProvider).obtenerFavoritos();
      if (mounted) setState(() => _totalFavoritos = favoritos.length);
    } catch (_) {
      // El contador es un extra — la pantalla no depende de esto.
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final usuario = session.usuario;
    final contexto = session.contextoActivo;
    final contextos = session.contextoAcceso?.contextos ?? [];
    final negociosActivos = contextos.where((c) => c.esNegocio).map((c) => c.negocioId).toSet().length;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tu cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Header ----
          SurfaceCard(
            padding: const EdgeInsets.all(20),
            radio: 20,
            child: Column(
              children: [
                GradientRingAvatar(url: usuario?.fotoUrl, radio: 40),
                const SizedBox(height: 12),
                Text(usuario?.nombre ?? '', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                TagPill(texto: _etiquetaRoles(contextos).toUpperCase(), color: scheme.secondary),
                const SizedBox(height: 10),
                if (usuario?.telefono != null)
                  IconTextRow(icono: Icons.phone_iphone_outlined, texto: usuario!.telefono),
                if (usuario?.email != null) IconTextRow(icono: Icons.mail_outline, texto: usuario!.email!),
              ],
            ),
          ),

          if (contextos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('MODO ACTIVO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.primary)),
            const SizedBox(height: 6),
            SurfaceCard(
              padding: const EdgeInsets.all(12),
              radio: 14,
              child: Row(
                children: [
                  IconAvatar(
                    icono: contexto != null && !contexto.esCliente ? Icons.storefront_outlined : Icons.person_outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_etiquetaContexto(contexto), style: Theme.of(context).textTheme.titleSmall),
                  ),
                  TextButton.icon(
                    onPressed: () => ref.read(sessionControllerProvider.notifier).volverASeleccionContexto(),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Cambiar'),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          Text('ACTIVIDAD Y PREFERENCIAS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: 6),
          MenuAccessTile(
            icono: Icons.favorite_border,
            titulo: 'Favoritos',
            subtitulo: 'Locales y profesionales guardados',
            contador: _totalFavoritos != null ? '$_totalFavoritos guardados' : null,
            onTap: () => context.push('/favoritos'),
          ),
          MenuAccessTile(
            icono: Icons.notifications_outlined,
            titulo: 'Preferencias de notificación',
            subtitulo: 'Alertas por WhatsApp y push de citas',
            onTap: () => context.push('/cuenta/notificaciones'),
          ),
          MenuAccessTile(
            icono: Icons.shield_outlined,
            titulo: 'Privacidad y consentimientos',
            subtitulo: 'Gestión de datos y seguridad',
            onTap: () => context.push('/cuenta/consentimientos'),
          ),

          const SizedBox(height: 16),
          Text('NEGOCIOS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: 6),
          MenuAccessTile(
            icono: Icons.storefront_outlined,
            titulo: 'Crear o administrar negocios',
            subtitulo: 'Acceso a tus locales de barbería o estética',
            contador: negociosActivos > 0 ? '$negociosActivos activo${negociosActivos == 1 ? '' : 's'}' : null,
            onTap: () => context.push('/negocios/nuevo'),
          ),

          const SizedBox(height: 16),
          Text('CUENTA Y SESIÓN', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: 6),
          MenuAccessTile(
            icono: Icons.logout,
            titulo: 'Cerrar sesión',
            subtitulo: 'Finalizar sesión en este dispositivo',
            onTap: () => ref.read(sessionControllerProvider.notifier).cerrarSesion(),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.peligro.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.peligro.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.delete_forever_outlined, color: AppColors.peligro, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Eliminar cuenta', style: Theme.of(context).textTheme.titleSmall)),
                    TagPill(texto: 'Irreversible', color: AppColors.peligro, alphaFondo: 0.2),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Anonimiza tu historial de citas y datos personales en FullPinta.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/cuenta/eliminar'),
                    icon: const Icon(Icons.warning_amber_rounded, size: 18),
                    label: const Text('Solicitar baja definitiva'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.peligro, side: const BorderSide(color: AppColors.peligro)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _etiquetaContexto(ContextoActivo? c) {
    if (c == null || c.esCliente) return 'Como cliente';
    if (c.esNegocio) return c.negocioNombre ?? 'Negocio';
    return 'Profesional en ${c.localNombre ?? ''}';
  }

  String _etiquetaRoles(List<ContextoItem> contextos) {
    final partes = <String>['Cliente'];
    if (contextos.any((c) => c.esNegocio)) partes.add('Administrador');
    if (contextos.any((c) => c.esProfesional)) partes.add('Profesional');
    return partes.join(' & ');
  }
}
