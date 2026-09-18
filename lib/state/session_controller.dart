import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../core/storage/secure_storage.dart';
import '../core/storage/session_prefs.dart';
import '../data/models/identity_models.dart';
import '../data/repositories/auth_repository.dart';

enum SessionStatus { cargando, sinSesion, necesitaSeleccionContexto, listo }

class SessionState {
  final SessionStatus status;
  final Usuario? usuario;
  final ContextoAcceso? contextoAcceso;
  final ContextoActivo? contextoActivo;
  final String? error;

  const SessionState({
    required this.status,
    this.usuario,
    this.contextoAcceso,
    this.contextoActivo,
    this.error,
  });

  const SessionState.inicial() : this(status: SessionStatus.cargando);

  SessionState copyWith({
    SessionStatus? status,
    Usuario? usuario,
    ContextoAcceso? contextoAcceso,
    ContextoActivo? contextoActivo,
    String? error,
  }) =>
      SessionState(
        status: status ?? this.status,
        usuario: usuario ?? this.usuario,
        contextoAcceso: contextoAcceso ?? this.contextoAcceso,
        contextoActivo: contextoActivo ?? this.contextoActivo,
        error: error,
      );
}

/// Orquesta la sesión completa: token guardado → `GET /auth/contexto` →
/// selector de contexto si hace falta (§3.2). Es la única fuente de verdad
/// que el router consulta para decidir a dónde mandar al usuario.
class SessionController extends StateNotifier<SessionState> {
  final AuthRepository _authRepository;

  SessionController(this._authRepository) : super(const SessionState.inicial());

  Future<void> inicializar() async {
    final token = await SecureStorage.leerToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: SessionStatus.sinSesion);
      return;
    }
    final usuarioCacheado = await SecureStorage.leerUsuario();
    state = state.copyWith(usuario: usuarioCacheado);
    await _resolverContexto();
  }

  /// Se llama justo después de un login/registro exitoso (OTP, correo...).
  Future<void> sesionIniciada(Usuario usuario) async {
    state = state.copyWith(usuario: usuario);
    await _resolverContexto();
  }

  Future<void> _resolverContexto() async {
    state = state.copyWith(status: SessionStatus.cargando);
    try {
      final contexto = await _authRepository.obtenerContexto();
      state = state.copyWith(contextoAcceso: contexto);

      if (!contexto.requiereSeleccion) {
        // 0 o 1 contexto además de cliente: entra directo.
        final activo = contexto.contextos.isEmpty
            ? ContextoActivo.cliente
            : ContextoActivo.desdeItem(contexto.contextos.first);
        await _activar(activo);
        return;
      }

      // Requiere selección: ¿el último contexto guardado sigue siendo válido?
      final guardado = await SessionPrefs.leerContexto();
      if (guardado != null) {
        final coincide = contexto.contextos.where((c) =>
            c.tipo == guardado['tipo'] &&
            c.rol == guardado['rol'] &&
            c.negocioId == guardado['negocio_id'] &&
            c.localId == guardado['local_id']);
        if (guardado['tipo'] == 'cliente') {
          state = state.copyWith(status: SessionStatus.listo, contextoActivo: ContextoActivo.cliente);
          return;
        }
        if (coincide.isNotEmpty) {
          state = state.copyWith(
            status: SessionStatus.listo,
            contextoActivo: ContextoActivo.desdeItem(coincide.first),
          );
          return;
        }
      }

      state = state.copyWith(status: SessionStatus.necesitaSeleccionContexto);
    } catch (e) {
      final error = DioClient.mapearError(e);
      if (error.esNoAutorizado) {
        await SecureStorage.borrarToken();
        state = state.copyWith(status: SessionStatus.sinSesion);
      } else {
        state = state.copyWith(status: SessionStatus.necesitaSeleccionContexto, error: error.mensaje);
      }
    }
  }

  Future<void> elegirContexto(ContextoActivo contexto) async {
    await _activar(contexto);
  }

  /// Vuelve a pedir `GET /auth/contexto` sin tocar el status ni el contexto
  /// activo — se usa después de crear un negocio o de que a alguien le den
  /// una nueva asignación, para que aparezca sin reiniciar la app.
  Future<void> refrescarContextoAcceso() async {
    try {
      final contexto = await _authRepository.obtenerContexto();
      state = state.copyWith(contextoAcceso: contexto);
    } catch (_) {
      // Silencioso: no es crítico, el usuario lo ve la próxima vez que entre.
    }
  }

  Future<void> _activar(ContextoActivo contexto) async {
    await SessionPrefs.guardarContexto(
      tipo: contexto.tipo,
      rol: contexto.rol,
      negocioId: contexto.negocioId,
      localId: contexto.localId,
    );
    state = state.copyWith(status: SessionStatus.listo, contextoActivo: contexto);
  }

  /// Vuelve al selector sin cerrar sesión (ej. botón "cambiar de contexto").
  void volverASeleccionContexto() {
    if (state.contextoAcceso == null) return;
    state = state.copyWith(status: SessionStatus.necesitaSeleccionContexto);
  }

  Future<void> cerrarSesion() async {
    await _authRepository.cerrarSesion();
    await SessionPrefs.limpiarContexto();
    state = const SessionState(status: SessionStatus.sinSesion);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final sessionControllerProvider = StateNotifierProvider<SessionController, SessionState>((ref) {
  return SessionController(ref.watch(authRepositoryProvider));
});
