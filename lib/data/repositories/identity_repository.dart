import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../models/favorito_model.dart';
import '../models/identity_models.dart';

/// Cuenta, consentimientos y favoritos (§13.1, §4.3).
class IdentityRepository {
  final Dio _dio;

  IdentityRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<List<Consentimiento>> obtenerConsentimientos() async {
    try {
      final res = await _dio.get('/consentimientos');
      return (res.data as List<dynamic>)
          .map((e) => Consentimiento.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Consentimiento> otorgarOrevocar({required String finalidad, required bool otorgado}) async {
    try {
      final res = await _dio.post('/consentimientos', data: {
        'finalidad': finalidad,
        'otorgado': otorgado,
      });
      return Consentimiento.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  /// Derecho de eliminación (§13.1) — sin vuelta atrás. Limpia también el
  /// token local, ya que el backend revoca todos los del usuario.
  Future<void> eliminarCuenta() async {
    try {
      await _dio.delete('/cuenta');
    } catch (e) {
      throw DioClient.mapearError(e);
    } finally {
      await SecureStorage.borrarToken();
    }
  }

  Future<List<Favorito>> obtenerFavoritos() async {
    try {
      final res = await _dio.get('/mis-favoritos');
      return (res.data as List<dynamic>)
          .map((e) => Favorito.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  /// Alta/baja con un solo endpoint (`api-referencia.md`): manda `local_id`
  /// **o** `profesional_id`, nunca ambos. Devuelve si quedó agregado.
  Future<bool> alternarFavorito({String? localId, String? profesionalId}) async {
    assert((localId == null) != (profesionalId == null),
        'Debe mandarse exactamente uno: localId o profesionalId');
    try {
      final res = await _dio.post('/favoritos', data: {
        if (localId != null) 'local_id': localId,
        if (profesionalId != null) 'profesional_id': profesionalId,
      });
      return res.data['agregado'] as bool? ?? false;
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<List<PreferenciaNotificacion>> obtenerPreferenciasNotificacion() async {
    try {
      final res = await _dio.get('/mis-preferencias-notificacion');
      return (res.data as List<dynamic>)
          .map((e) => PreferenciaNotificacion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<List<PreferenciaNotificacion>> actualizarPreferenciasNotificacion(
    List<PreferenciaNotificacion> preferencias,
  ) async {
    try {
      final res = await _dio.put('/mis-preferencias-notificacion', data: {
        'preferencias': preferencias.map((e) => e.toJson()).toList(),
      });
      return (res.data as List<dynamic>)
          .map((e) => PreferenciaNotificacion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }
}
