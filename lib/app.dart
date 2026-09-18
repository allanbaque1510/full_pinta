import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/session_controller.dart';

class FullPintaApp extends ConsumerStatefulWidget {
  const FullPintaApp({super.key});

  @override
  ConsumerState<FullPintaApp> createState() => _FullPintaAppState();
}

class _FullPintaAppState extends ConsumerState<FullPintaApp> {
  @override
  void initState() {
    super.initState();
    // Dispara la resolución de sesión (token guardado -> contexto -> ruta
    // inicial) apenas arranca la app; el router reacciona solo vía
    // `refreshListenable` cuando el estado cambie.
    Future.microtask(() => ref.read(sessionControllerProvider.notifier).inicializar());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'FullPinta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      // El sistema de diseño (ver design/) es dark-first a propósito, no un
      // modo alternativo — se fuerza para que la marca se vea consistente
      // sin depender de la preferencia del sistema operativo.
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
