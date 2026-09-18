import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../models/identity_models.dart';

/// Resultado de cualquiera de los tres métodos de login/registro (§4.3):
/// todos devuelven el mismo shape `{ usuario, token }`.
class SesionIniciada {
  final Usuario usuario;
  final String token;

  const SesionIniciada({required this.usuario, required this.token});

  factory SesionIniciada.fromJson(Map<String, dynamic> json) => SesionIniciada(
        usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
        token: json['token'] as String,
      );
}

class AuthRepository {
  final Dio _dio;

  AuthRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<int> solicitarOtp(String telefono) async {
    try {
      final res = await _dio.post('/auth/otp/solicitar', data: {'telefono': telefono});
      return (res.data['expira_en_minutos'] as int?) ?? 5;
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  /// `nombre` solo es obligatorio si el teléfono es nuevo — el caller decide
  /// cuándo pedirlo (ver `docs/api-referencia.md`, POST /auth/otp/verificar).
  Future<SesionIniciada> verificarOtp({
    required String telefono,
    required String codigo,
    String? nombre,
  }) async {
    try {
      final res = await _dio.post('/auth/otp/verificar', data: {
        'telefono': telefono,
        'codigo': codigo,
        if (nombre != null && nombre.isNotEmpty) 'nombre': nombre,
      });
      final sesion = SesionIniciada.fromJson(res.data as Map<String, dynamic>);
      await SecureStorage.guardarToken(sesion.token);
      await SecureStorage.guardarUsuario(sesion.usuario);
      return sesion;
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<SesionIniciada> registrarPorCorreo({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
  }) async {
    try {
      final res = await _dio.post('/auth/registro', data: {
        'nombre': nombre,
        'email': email,
        'password': password,
        'telefono': telefono,
      });
      final sesion = SesionIniciada.fromJson(res.data as Map<String, dynamic>);
      await SecureStorage.guardarToken(sesion.token);
      await SecureStorage.guardarUsuario(sesion.usuario);
      return sesion;
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<SesionIniciada> loginPorCorreo({required String email, required String password}) async {
    try {
      final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      final sesion = SesionIniciada.fromJson(res.data as Map<String, dynamic>);
      await SecureStorage.guardarToken(sesion.token);
      await SecureStorage.guardarUsuario(sesion.usuario);
      return sesion;
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<ContextoAcceso> obtenerContexto() async {
    try {
      final res = await _dio.get('/auth/contexto');
      return ContextoAcceso.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> cerrarSesion() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Si el token ya no era válido, igual limpiamos localmente.
    } finally {
      await SecureStorage.borrarToken();
    }
  }
}
