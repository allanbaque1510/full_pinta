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
      // El mockup oficial (context/Image.jpg) es claro: se fuerza para que la
      // marca se vea igual sin depender de la preferencia del sistema.
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
