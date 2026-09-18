import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../../core/network/idempotency.dart';
import '../models/scheduling_models.dart';

class SchedulingRepository {
  final Dio _dio;

  SchedulingRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<List<SlotDisponible>> disponibilidad(
    String localId, {
    required String fecha,
    required List<String> servicioLocalIds,
    String? profesionalId,
  }) async {
    try {
      final res = await _dio.get('/locales/$localId/disponibilidad', queryParameters: {
        'fecha': fecha,
        'servicios[]': servicioLocalIds,
        if (profesionalId != null) 'profesional_id': profesionalId,
      });
      return (res.data as List<dynamic>)
          .map((e) => SlotDisponible.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<List<Cita>> agendaDelLocal(String localId, {String? fecha, String? profesionalId, String? estado}) async {
    try {
      final res = await _dio.get('/locales/$localId/citas', queryParameters: {
        if (fecha != null) 'fecha': fecha,
        if (profesionalId != null) 'profesional_id': profesionalId,
        if (estado != null) 'estado': estado,
      });
      return (res.data as List<dynamic>).map((e) => Cita.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Cita> obtenerCita(String citaId) async {
    try {
      final res = await _dio.get('/citas/$citaId');
      return Cita.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<List<Cita>> misCitas({String? estado, String? localId}) async {
    try {
      final res = await _dio.get('/mis-citas', queryParameters: {
        if (estado != null) 'estado': estado,
        if (localId != null) 'local_id': localId,
      });
      return (res.data as List<dynamic>).map((e) => Cita.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Cita> crearCita(
    String localId, {
    required String profesionalId,
    required List<String> servicios,
    required DateTime inicio,
    String? recursoId,
    String paraTipo = 'titular',
    String? paraNombre,
    String? mascotaId,
    String? notaCliente,
  }) async {
    try {
      final res = await _dio.post(
        '/locales/$localId/citas',
        data: {
          'profesional_id': profesionalId,
          'servicios': servicios,
          'inicio': inicio.toUtc().toIso8601String(),
          if (recursoId != null) 'recurso_id': recursoId,
          'para_tipo': paraTipo,
          if (paraNombre != null) 'para_nombre': paraNombre,
          if (mascotaId != null) 'mascota_id': mascotaId,
          if (notaCliente != null && notaCliente.isNotEmpty) 'nota_cliente': notaCliente,
        },
        options: Options(headers: {'Idempotency-Key': Idempotency.nuevaClave()}),
      );
      return Cita.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Cita> crearWalkIn(
    String localId, {
    required String profesionalId,
    required List<String> servicios,
    required DateTime inicio,
    String? recursoId,
    String? clienteId,
    String? nombre,
    String? telefono,
    String paraTipo = 'titular',
    String? notaCliente,
  }) async {
    try {
      final res = await _dio.post(
        '/locales/$localId/citas/walk-in',
        data: {
          'profesional_id': profesionalId,
          'servicios': servicios,
          'inicio': inicio.toUtc().toIso8601String(),
          if (recursoId != null) 'recurso_id': recursoId,
          if (clienteId != null) 'cliente_id': clienteId,
          if (clienteId == null) 'nombre': nombre,
          if (clienteId == null) 'telefono': telefono,
          'para_tipo': paraTipo,
          if (notaCliente != null && notaCliente.isNotEmpty) 'nota_cliente': notaCliente,
        },
        options: Options(headers: {'Idempotency-Key': Idempotency.nuevaClave()}),
      );
      return Cita.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Cita> confirmar(String citaId) => _accion(citaId, 'confirmar');

  Future<Cita> iniciar(String citaId) => _accion(citaId, 'iniciar');

  Future<Cita> completar(String citaId, {double? propina}) async {
    try {
      final res = await _dio.post('/citas/$citaId/completar', data: {
        if (propina != null) 'propina': propina,
      });
      return Cita.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Cita> noShow(String citaId) => _accion(citaId, 'no-show');

  Future<Cita> cancelar(String citaId, {String? motivo}) async {
    try {
      final res = await _dio.post(
        '/citas/$citaId/cancelar',
        data: {if (motivo != null && motivo.isNotEmpty) 'motivo': motivo},
        options: Options(headers: {'Idempotency-Key': Idempotency.nuevaClave()}),
      );
      return Cita.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Cita> reagendar(
    String citaId, {
    required String profesionalId,
    required List<String> servicios,
    required DateTime inicio,
    String? recursoId,
  }) async {
    try {
      final res = await _dio.post('/citas/$citaId/reagendar', data: {
        'profesional_id': profesionalId,
        'servicios': servicios,
        'inicio': inicio.toUtc().toIso8601String(),
        if (recursoId != null) 'recurso_id': recursoId,
      });
      return Cita.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Cita> agregarProducto(String citaId, {required String productoId, int cantidad = 1}) async {
    try {
      final res = await _dio.post('/citas/$citaId/productos', data: {
        'producto_id': productoId,
        'cantidad': cantidad,
      });
      return Cita.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Cita> _accion(String citaId, String verbo) async {
    try {
      final res = await _dio.post('/citas/$citaId/$verbo');
      return Cita.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Lista de espera ----

  Future<List<Espera>> listarEsperas(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/esperas');
      return (res.data as List<dynamic>).map((e) => Espera.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<List<Espera>> anotarseEnEspera(
    String localId, {
    required String servicioLocalId,
    required String fechaDeseada,
    String? profesionalId,
    String? desde,
    String? hasta,
  }) async {
    try {
      final res = await _dio.post('/locales/$localId/esperas', data: {
        'servicio_local_id': servicioLocalId,
        'fecha_deseada': fechaDeseada,
        if (profesionalId != null) 'profesional_id': profesionalId,
        if (desde != null) 'desde': desde,
        if (hasta != null) 'hasta': hasta,
      });
      return (res.data as List<dynamic>).map((e) => Espera.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }
}
