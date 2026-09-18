import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../models/reviews_models.dart';

class ReviewsRepository {
  final Dio _dio;

  ReviewsRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<Resena> crearResena(
    String citaId, {
    required int puntajeLocal,
    int? puntajeProfesional,
    int? puntualidad,
    int? limpieza,
    String? comentario,
  }) async {
    try {
      final res = await _dio.post('/citas/$citaId/resenas', data: {
        'puntaje_local': puntajeLocal,
        if (puntajeProfesional != null) 'puntaje_profesional': puntajeProfesional,
        if (puntualidad != null) 'puntualidad': puntualidad,
        if (limpieza != null) 'limpieza': limpieza,
        if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
      });
      return Resena.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<List<Resena>> listarResenasDelLocal(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/resenas');
      return (res.data as List<dynamic>).map((e) => Resena.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Resena> responder(String resenaId, String respuesta) async {
    try {
      final res = await _dio.post('/resenas/$resenaId/responder', data: {'respuesta_local': respuesta});
      return Resena.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> crearReporte({
    required String tipo,
    required String objetoId,
    required String motivo,
    String? detalle,
  }) async {
    try {
      await _dio.post('/reportes', data: {
        'tipo': tipo,
        'objeto_id': objetoId,
        'motivo': motivo,
        if (detalle != null && detalle.isNotEmpty) 'detalle': detalle,
      });
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }
}
