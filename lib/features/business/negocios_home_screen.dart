import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/menu_access_tile.dart';
import '../../state/session_controller.dart';

/// No existe un `GET /negocios` que liste "los míos" — la fuente de esa
/// lista es `GET /auth/contexto` (ya resuelto en la sesión): cada fila
/// `tipo: "negocio"` es un negocio donde el usuario administra.
class NegociosHomeScreen extends ConsumerWidget {
  const NegociosHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextos = ref.watch(sessionControllerProvider).contextoAcceso?.contextos ?? [];
    final negocios = <String, String>{};
    for (final c in contextos.where((c) => c.esNegocio)) {
      if (c.negocioId != null) negocios[c.negocioId!] = c.negocioNombre ?? 'Negocio';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis negocios'),
        actions: [
          if (negocios.isNotEmpty)
            IconButton(onPressed: () => context.push('/negocios/nuevo'), icon: const Icon(Icons.add_business_outlined)),
        ],
      ),
      body: negocios.isEmpty
          ? EmptyState(
              mensaje: 'Todavía no administras ningún negocio.',
              icono: Icons.storefront_outlined,
              accion: FilledButton.icon(
                onPressed: () => context.push('/negocios/nuevo'),
                icon: const Icon(Icons.add),
                label: const Text('Crear negocio'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: negocios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final entry = negocios.entries.elementAt(i);
                return MenuAccessTile(
                  icono: Icons.storefront_outlined,
                  titulo: entry.value,
                  onTap: () => context.push('/negocios/${entry.key}'),
                );
              },
            ),
    );
  }
}
