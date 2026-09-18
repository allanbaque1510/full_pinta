import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/directory_models.dart';
import '../../data/models/scheduling_models.dart';
import '../../features/account/account_home_screen.dart';
import '../../features/account/consentimientos_screen.dart';
import '../../features/account/eliminar_cuenta_screen.dart';
import '../../features/account/favoritos_screen.dart';
import '../../features/account/preferencias_notificacion_screen.dart';
import '../../features/agenda/agenda_dia_screen.dart';
import '../../features/agenda/cita_staff_detalle_screen.dart';
import '../../features/agenda/walk_in_form_screen.dart';
import '../../features/auth/context_selector_screen.dart';
import '../../features/auth/email_login_screen.dart';
import '../../features/auth/email_registro_screen.dart';
import '../../features/auth/otp_solicitar_screen.dart';
import '../../features/auth/otp_verificar_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/booking/booking_flow_screen.dart';
import '../../features/booking/cita_detalle_screen.dart';
import '../../features/booking/reagendar_screen.dart';
import '../../features/booking/resena_form_screen.dart';
import '../../features/business/local_admin_screen.dart';
import '../../features/business/local_amenidades_screen.dart';
import '../../features/business/local_fotos_screen.dart';
import '../../features/business/local_form_screen.dart';
import '../../features/business/local_horarios_screen.dart';
import '../../features/business/local_productos_screen.dart';
import '../../features/business/local_servicios_screen.dart';
import '../../features/business/negocio_detalle_screen.dart';
import '../../features/business/negocio_form_screen.dart';
import '../../features/business/solicitudes_catalogo_screen.dart';
import '../../features/discovery/local_perfil_publico_screen.dart';
import '../../features/discovery/profesional_perfil_publico_screen.dart';
import '../../features/reviews_staff/local_resenas_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/staffing/asignacion_turnos_screen.dart';
import '../../features/staffing/excepciones_screen.dart';
import '../../features/staffing/profesional_admin_screen.dart';
import '../../features/staffing/profesional_fotos_screen.dart';
import '../../features/staffing/profesional_form_screen.dart';
import '../../features/staffing/profesional_habilidades_screen.dart';
import '../../features/staffing/profesional_turno_fechas_screen.dart';
import '../../features/staffing/profesionales_list_screen.dart';
import '../../features/staffing/recursos_screen.dart';
import '../../state/session_controller.dart';

/// Puente entre Riverpod y `refreshListenable` de go_router: cuando cambia
/// la sesión (login, logout, contexto elegido...), el router debe
/// re-evaluar `redirect` aunque no haya habido una navegación explícita
/// (ej. la sesión termina de resolverse mientras el usuario sigue en splash).
class _RouterRefreshNotifier extends ChangeNotifier {
  void avisar() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref.listen(sessionControllerProvider, (_, __) => refresh.avisar());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final loc = state.matchedLocation;
      final enFlujoAuth = loc.startsWith('/login') || loc.startsWith('/registro');
      final enSplash = loc == '/splash';
      final enContexto = loc == '/contexto';

      switch (session.status) {
        case SessionStatus.cargando:
          return enSplash ? null : '/splash';
        case SessionStatus.sinSesion:
          return enFlujoAuth ? null : '/login';
        case SessionStatus.necesitaSeleccionContexto:
          return enContexto ? null : '/contexto';
        case SessionStatus.listo:
          return (enSplash || enFlujoAuth || enContexto) ? '/' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const OtpSolicitarScreen()),
      GoRoute(
        path: '/login/verificar',
        builder: (context, state) => OtpVerificarScreen(telefono: state.extra as String),
      ),
      GoRoute(path: '/login/correo', builder: (context, state) => const EmailLoginScreen()),
      GoRoute(path: '/registro/correo', builder: (context, state) => const EmailRegistroScreen()),
      GoRoute(path: '/contexto', builder: (context, state) => const ContextSelectorScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeShell()),

      // Descubrimiento y agendamiento (cliente)
      GoRoute(
        path: '/local/:localId',
        builder: (context, state) => LocalPerfilPublicoScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/local/:localId/agendar',
        builder: (context, state) => BookingFlowScreen(local: state.extra as LocalPerfilPublico),
      ),
      GoRoute(
        path: '/profesional/:profesionalId',
        builder: (context, state) =>
            ProfesionalPerfilPublicoScreen(profesionalId: state.pathParameters['profesionalId']!),
      ),
      GoRoute(
        path: '/mis-citas/:citaId',
        builder: (context, state) => CitaDetalleScreen(citaId: state.pathParameters['citaId']!),
      ),
      GoRoute(
        path: '/mis-citas/:citaId/reagendar',
        builder: (context, state) => ReagendarScreen(citaOriginal: state.extra as Cita),
      ),
      GoRoute(
        path: '/mis-citas/:citaId/resena',
        builder: (context, state) => ResenaFormScreen(cita: state.extra as Cita),
      ),
      GoRoute(path: '/favoritos', builder: (context, state) => const FavoritosScreen()),

      // Cuenta
      GoRoute(path: '/cuenta', builder: (context, state) => const AccountHomeScreen()),
      GoRoute(path: '/cuenta/consentimientos', builder: (context, state) => const ConsentimientosScreen()),
      GoRoute(path: '/cuenta/eliminar', builder: (context, state) => const EliminarCuentaScreen()),
      GoRoute(
        path: '/cuenta/notificaciones',
        builder: (context, state) => const PreferenciasNotificacionScreen(),
      ),

      // Negocio
      GoRoute(path: '/negocios/nuevo', builder: (context, state) => const NegocioFormScreen()),
      GoRoute(
        path: '/negocios/:negocioId',
        builder: (context, state) => NegocioDetalleScreen(negocioId: state.pathParameters['negocioId']!),
      ),
      GoRoute(
        path: '/negocios/:negocioId/locales/nuevo',
        builder: (context, state) => LocalFormScreen(negocioId: state.pathParameters['negocioId']!),
      ),

      // Administración del local
      GoRoute(
        path: '/locales/:localId/admin',
        builder: (context, state) => LocalAdminScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/agenda',
        builder: (context, state) => AgendaDiaScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/agenda/walk-in',
        builder: (context, state) => WalkInFormScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/agenda/:citaId',
        builder: (context, state) => CitaStaffDetalleScreen(citaId: state.pathParameters['citaId']!),
      ),
      GoRoute(
        path: '/locales/:localId/horarios',
        builder: (context, state) => LocalHorariosScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/amenidades',
        builder: (context, state) => LocalAmenidadesScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/fotos',
        builder: (context, state) => LocalFotosScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/servicios',
        builder: (context, state) => LocalServiciosScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/productos',
        builder: (context, state) => LocalProductosScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/solicitudes-catalogo',
        builder: (context, state) => SolicitudesCatalogoScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/resenas',
        builder: (context, state) => LocalResenasScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/personal',
        builder: (context, state) => ProfesionalesListScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/personal/nuevo',
        builder: (context, state) => ProfesionalFormScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/recursos',
        builder: (context, state) => RecursosScreen(localId: state.pathParameters['localId']!),
      ),
      GoRoute(
        path: '/locales/:localId/excepciones',
        builder: (context, state) => ExcepcionesScreen(
          origen: OrigenExcepcion.local,
          origenId: state.pathParameters['localId']!,
          titulo: 'Cierres y excepciones',
        ),
      ),

      // Profesional (persona), dentro del contexto de un local
      GoRoute(
        path: '/profesionales/:profesionalId/admin',
        builder: (context, state) => ProfesionalAdminScreen(
          profesionalId: state.pathParameters['profesionalId']!,
          localId: state.extra as String,
        ),
      ),
      GoRoute(
        path: '/profesionales/:profesionalId/turno-fechas',
        builder: (context, state) => ProfesionalTurnoFechasScreen(
          profesionalId: state.pathParameters['profesionalId']!,
          localId: state.extra as String,
        ),
      ),
      GoRoute(
        path: '/profesionales/:profesionalId/habilidades',
        builder: (context, state) => ProfesionalHabilidadesScreen(
          profesionalId: state.pathParameters['profesionalId']!,
          localId: state.extra as String,
        ),
      ),
      GoRoute(
        path: '/profesionales/:profesionalId/fotos',
        builder: (context, state) => ProfesionalFotosScreen(profesionalId: state.pathParameters['profesionalId']!),
      ),
      GoRoute(
        path: '/profesionales/:profesionalId/excepciones',
        builder: (context, state) => ExcepcionesScreen(
          origen: OrigenExcepcion.profesional,
          origenId: state.pathParameters['profesionalId']!,
          titulo: 'Ausencias y bloqueos',
        ),
      ),
      GoRoute(
        path: '/asignaciones/:asignacionId/turnos',
        builder: (context, state) => AsignacionTurnosScreen(asignacionId: state.pathParameters['asignacionId']!),
      ),
    ],
  );
});
