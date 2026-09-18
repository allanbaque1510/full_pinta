import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de UI no sensibles (nada de sesión ni tokens acá).
/// Guarda el último contexto activo elegido en el selector (§3.2) para no
/// mostrarlo de nuevo en cada arranque si sigue siendo válido.
class SessionPrefs {
  SessionPrefs._();

  static const _kContextoTipo = 'contexto_tipo';
  static const _kContextoRol = 'contexto_rol';
  static const _kContextoNegocioId = 'contexto_negocio_id';
  static const _kContextoLocalId = 'contexto_local_id';

  static Future<void> guardarContexto({
    required String tipo,
    required String rol,
    String? negocioId,
    String? localId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kContextoTipo, tipo);
    await prefs.setString(_kContextoRol, rol);
    if (negocioId != null) {
      await prefs.setString(_kContextoNegocioId, negocioId);
    } else {
      await prefs.remove(_kContextoNegocioId);
    }
    if (localId != null) {
      await prefs.setString(_kContextoLocalId, localId);
    } else {
      await prefs.remove(_kContextoLocalId);
    }
  }

  static Future<Map<String, String?>?> leerContexto() async {
    final prefs = await SharedPreferences.getInstance();
    final tipo = prefs.getString(_kContextoTipo);
    final rol = prefs.getString(_kContextoRol);
    if (tipo == null || rol == null) return null;
    return {
      'tipo': tipo,
      'rol': rol,
      'negocio_id': prefs.getString(_kContextoNegocioId),
      'local_id': prefs.getString(_kContextoLocalId),
    };
  }

  static Future<void> limpiarContexto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kContextoTipo);
    await prefs.remove(_kContextoRol);
    await prefs.remove(_kContextoNegocioId);
    await prefs.remove(_kContextoLocalId);
  }
}
