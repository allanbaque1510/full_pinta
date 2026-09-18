import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/icon_avatar.dart';
import '../../core/widgets/tag_pill.dart';
import '../../data/models/identity_models.dart';
import '../../state/session_controller.dart';

/// Selector de "sombreros" del §3.2: un cliente puede ser también dueño de
/// un negocio y barbero en otro local, todo a la vez. Se muestra cuando
/// `GET /auth/contexto` marca `requiere_seleccion: true`.
class ContextSelectorScreen extends ConsumerWidget {
  const ContextSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final contextos = session.contextoAcceso?.contextos ?? [];
    final scheme = Theme.of(context).colorScheme;
    final nombre = session.usuario?.nombre.split(' ').first ?? '';

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text('Hola${nombre.isNotEmpty ? ', $nombre' : ''} 👋', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('¿Cómo quieres ingresar hoy?', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text(
              'Puedes cambiar de perfil en cualquier momento desde tu cuenta.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            _TarjetaContexto(
              icono: Icons.explore_outlined,
              iconoColor: scheme.secondary,
              titulo: 'Como cliente',
              etiqueta: 'Predeterminado',
              etiquetaColor: scheme.secondary,
              subtitulo: 'Explora salones, reserva turnos y gestiona tus citas personales.',
              onTap: () => ref.read(sessionControllerProvider.notifier).elegirContexto(ContextoActivo.cliente),
            ),
            ...contextos.map((c) => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _TarjetaContexto(
                    icono: c.esNegocio ? Icons.storefront_outlined : Icons.content_cut,
                    iconoColor: c.esNegocio ? scheme.primary : scheme.tertiary,
                    titulo: c.esNegocio ? (c.negocioNombre ?? 'Negocio') : (c.localNombre ?? 'Local'),
                    etiqueta: c.esNegocio ? _etiquetaRolNegocio(c.rol) : 'Profesional',
                    etiquetaColor: c.esNegocio ? scheme.primary : scheme.tertiary,
                    subtitulo: c.esNegocio
                        ? 'Control de agenda, personal y catálogo del negocio.'
                        : 'Tu estación de trabajo y agenda en ${c.localNombre ?? 'el local'}.',
                    onTap: () => ref
                        .read(sessionControllerProvider.notifier)
                        .elegirContexto(ContextoActivo.desdeItem(c)),
                  ),
                )),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.push('/negocios/nuevo'),
              icon: Icon(Icons.add_business_outlined, color: scheme.primary),
              label: const Text('Registrar un nuevo negocio o local'),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Sesión unificada segura con cifrado FullPinta',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _etiquetaRolNegocio(String rol) {
    switch (rol) {
      case 'propietario':
        return 'Propietario';
      case 'admin':
        return 'Administrador';
      case 'recepcion':
        return 'Recepción';
      default:
        return rol;
    }
  }
}

class _TarjetaContexto extends StatelessWidget {
  final IconData icono;
  final Color iconoColor;
  final String titulo;
  final String etiqueta;
  final Color etiquetaColor;
  final String subtitulo;
  final VoidCallback onTap;

  const _TarjetaContexto({
    required this.icono,
    required this.iconoColor,
    required this.titulo,
    required this.etiqueta,
    required this.etiquetaColor,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconAvatar(icono: icono, color: iconoColor, radio: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: Theme.of(context).textTheme.headlineSmall, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        TagPill(texto: etiqueta, color: etiquetaColor),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: scheme.surfaceContainerHigh,
                    child: Icon(Icons.arrow_forward, size: 16, color: scheme.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(subtitulo, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
