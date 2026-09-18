import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/identity_models.dart';

/// Guarda el token de Sanctum y una copia liviana del usuario logueado.
/// Nunca se guarda en shared_preferences: es la única pieza de sesión que
/// debe vivir cifrada.
///
/// La API no expone un endpoint "quién soy" fuera del login (ver
/// `docs/api-referencia.md`) — el usuario que devuelve `POST /auth/otp/verificar`
/// (o Google/correo) se cachea acá para poder pintar la pantalla de cuenta
/// sin volver a pedir credenciales en cada arranque.
class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _usuarioKey = 'auth_usuario';

  static Future<void> guardarToken(String token) => _storage.write(key: _tokenKey, value: token);

  static Future<String?> leerToken() => _storage.read(key: _tokenKey);

  static Future<void> guardarUsuario(Usuario usuario) =>
      _storage.write(key: _usuarioKey, value: jsonEncode(usuario.toJson()));

  static Future<Usuario?> leerUsuario() async {
    final raw = await _storage.read(key: _usuarioKey);
    if (raw == null) return null;
    try {
      return Usuario.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> borrarToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usuarioKey);
  }
}
