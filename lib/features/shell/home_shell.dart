import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/identity_models.dart';
import '../../state/session_controller.dart';
import '../account/account_home_screen.dart';
import '../agenda/agenda_dia_screen.dart';
import '../booking/mis_citas_screen.dart';
import '../business/negocios_home_screen.dart';
import '../discovery/search_home_screen.dart';
import '../reviews_staff/local_resenas_screen.dart';

/// Cascarón con navegación inferior. Las pestañas cambian según el
/// contexto activo (§3.2): cliente, negocio o profesional. El selector de
/// contexto decide qué "sombrero" está puesto; esto solo pinta el shell
/// correspondiente.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final contexto = ref.watch(sessionControllerProvider).contextoActivo ?? ContextoActivo.cliente;

    final tabs = _tabsPara(contexto);
    if (_indice >= tabs.length) _indice = 0;
    final session = ref.watch(sessionControllerProvider);
    final tieneMasContextos = (session.contextoAcceso?.contextos.length ?? 0) > 0;

    return Scaffold(
      body: Column(
        children: [
          if (!contexto.esCliente || tieneMasContextos) _BarraDeModo(contexto: contexto),
          Expanded(
            child: IndexedStack(
              index: _indice,
              children: tabs.map((t) => t.pantalla).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icono), label: t.etiqueta))
            .toList(),
      ),
    );
  }

  List<_Tab> _tabsPara(ContextoActivo contexto) {
    if (contexto.esNegocio) {
      return [
        _Tab('Negocios', Icons.storefront_outlined, const NegociosHomeScreen()),
        if (contexto.localId != null)
          _Tab('Agenda', Icons.event_note_outlined, AgendaDiaScreen(localId: contexto.localId!))
        else
          _Tab('Agenda', Icons.event_note_outlined, const _SeleccionaLocalPlaceholder()),
        if (contexto.localId != null)
          _Tab('Reseñas', Icons.star_outline, LocalResenasScreen(localId: contexto.localId!))
        else
          _Tab('Reseñas', Icons.star_outline, const _SeleccionaLocalPlaceholder()),
        const _Tab('Cuenta', Icons.person_outline, AccountHomeScreen()),
      ];
    }

    if (contexto.esProfesional && contexto.localId != null) {
      return [
        _Tab('Mi agenda', Icons.event_note_outlined,
            AgendaDiaScreen(localId: contexto.localId!, profesionalPropioId: null)),
        const _Tab('Cuenta', Icons.person_outline, AccountHomeScreen()),
      ];
    }

    return const [
      _Tab('Buscar', Icons.search, SearchHomeScreen()),
      _Tab('Mis citas', Icons.event_available_outlined, MisCitasScreen()),
      _Tab('Cuenta', Icons.person_outline, AccountHomeScreen()),
    ];
  }
}

class _Tab {
  final String etiqueta;
  final IconData icono;
  final Widget pantalla;

  const _Tab(this.etiqueta, this.icono, this.pantalla);
}

class _SeleccionaLocalPlaceholder extends StatelessWidget {
  const _SeleccionaLocalPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Elige un local desde la pestaña Negocios.')),
    );
  }
}

/// Franja superior que deja claro con qué "sombrero" se está viendo la app
/// (§3.2) y ofrece un atajo directo para cambiarlo, sin pasar por Cuenta.
class _BarraDeModo extends ConsumerWidget {
  final ContextoActivo contexto;

  const _BarraDeModo({required this.contexto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final etiqueta = switch (contexto.tipo) {
      'negocio' => 'Modo ${_etiquetaRol(contexto.rol)}',
      'profesional' => 'Modo Profesional',
      _ => 'Modo Cliente',
    };

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: scheme.tertiary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(etiqueta, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => ref.read(sessionControllerProvider.notifier).volverASeleccionContexto(),
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  String _etiquetaRol(String rol) => switch (rol) {
        'propietario' => 'Propietario',
        'admin' => 'Administrador',
        'recepcion' => 'Recepción',
        _ => rol,
      };
}
