import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../models/staffing_models.dart';

class StaffingRepository {
  final Dio _dio;

  StaffingRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  // ---- Profesionales ----

  Future<List<Profesional>> listarProfesionales(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/profesionales');
      return (res.data as List<dynamic>)
          .map((e) => Profesional.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  /// Alta de un profesional nuevo + su primera asignación (§4.6). Para sumar
  /// uno que ya existe a otro local, ver [crearAsignacion].
  Future<Profesional> crearProfesional(
    String localId, {
    required String nombre,
    String? alias,
    String? bio,
    String? fotoUrl,
    bool independiente = false,
    bool perfilPublico = true,
    int traslacionMin = 30,
    required String rol,
    required String modalidad,
    required double comisionPct,
    String? desde,
  }) async {
    try {
      final res = await _dio.post('/locales/$localId/profesionales', data: {
        'nombre': nombre,
        if (alias != null && alias.isNotEmpty) 'alias': alias,
        if (bio != null && bio.isNotEmpty) 'bio': bio,
        if (fotoUrl != null && fotoUrl.isNotEmpty) 'foto_url': fotoUrl,
        'independiente': independiente,
        'perfil_publico': perfilPublico,
        'traslado_min': traslacionMin,
        'rol': rol,
        'modalidad': modalidad,
        'comision_pct': comisionPct,
        if (desde != null) 'desde': desde,
      });
      return Profesional.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Profesional> obtenerProfesional(String profesionalId) async {
    try {
      final res = await _dio.get('/profesionales/$profesionalId');
      return Profesional.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Profesional> actualizarProfesional(
    String profesionalId, {
    String? nombre,
    String? alias,
    String? bio,
    String? fotoUrl,
    bool? independiente,
    bool? perfilPublico,
    int? traslacionMin,
  }) async {
    try {
      final res = await _dio.patch('/profesionales/$profesionalId', data: {
        if (nombre != null) 'nombre': nombre,
        if (alias != null) 'alias': alias,
        if (bio != null) 'bio': bio,
        if (fotoUrl != null) 'foto_url': fotoUrl,
        if (independiente != null) 'independiente': independiente,
        if (perfilPublico != null) 'perfil_publico': perfilPublico,
        if (traslacionMin != null) 'traslado_min': traslacionMin,
      });
      return Profesional.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<ProfesionalPerfilPublico> perfilPublicoProfesional(String profesionalId) async {
    try {
      final res = await _dio.get('/profesionales/$profesionalId/perfil-publico');
      return ProfesionalPerfilPublico.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Fotos del profesional ----

  Future<List<ProfesionalFoto>> listarFotosProfesional(String profesionalId) async {
    try {
      final res = await _dio.get('/profesionales/$profesionalId/fotos');
      return (res.data as List<dynamic>)
          .map((e) => ProfesionalFoto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<ProfesionalFoto> crearFotoProfesional(String profesionalId, {required String url, int orden = 0}) async {
    try {
      final res = await _dio.post('/profesionales/$profesionalId/fotos', data: {
        'url': url,
        'orden': orden,
      });
      return ProfesionalFoto.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> eliminarFotoProfesional(String profesionalId, String fotoId) async {
    try {
      await _dio.delete('/profesionales/$profesionalId/fotos/$fotoId');
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Asignaciones ----

  Future<List<Asignacion>> listarAsignaciones(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/asignaciones');
      return (res.data as List<dynamic>)
          .map((e) => Asignacion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Asignacion> crearAsignacion(
    String localId, {
    required String profesionalId,
    required String rol,
    required String modalidad,
    required double comisionPct,
    String? desde,
  }) async {
    try {
      final res = await _dio.post('/locales/$localId/asignaciones', data: {
        'profesional_id': profesionalId,
        'rol': rol,
        'modalidad': modalidad,
        'comision_pct': comisionPct,
        if (desde != null) 'desde': desde,
      });
      return Asignacion.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Asignacion> terminarAsignacion(String asignacionId, {String? hasta}) async {
    try {
      final res = await _dio.post('/asignaciones/$asignacionId/terminar', data: {
        if (hasta != null) 'hasta': hasta,
      });
      return Asignacion.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Turnos recurrentes ----

  Future<List<Turno>> listarTurnos(String asignacionId) async {
    try {
      final res = await _dio.get('/asignaciones/$asignacionId/turnos');
      return (res.data as List<dynamic>).map((e) => Turno.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Turno> crearTurno(
    String asignacionId, {
    required int diaSemana,
    required String entra,
    required String sale,
    required String vigenteDesde,
    String? vigenteHasta,
  }) async {
    try {
      final res = await _dio.post('/asignaciones/$asignacionId/turnos', data: {
        'dia_semana': diaSemana,
        'entra': entra,
        'sale': sale,
        'vigente_desde': vigenteDesde,
        'vigente_hasta': vigenteHasta,
      });
      return Turno.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> eliminarTurno(String turnoId) async {
    try {
      await _dio.delete('/turnos/$turnoId');
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Overrides por fecha ----

  Future<List<TurnoFecha>> listarTurnoFechas(String profesionalId) async {
    try {
      final res = await _dio.get('/profesionales/$profesionalId/turno-fechas');
      return (res.data as List<dynamic>)
          .map((e) => TurnoFecha.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<TurnoFecha> crearTurnoFecha(
    String profesionalId, {
    required String localId,
    required String fecha,
    required String tipo,
    String? entra,
    String? sale,
    String? nota,
  }) async {
    try {
      final res = await _dio.post('/profesionales/$profesionalId/turno-fechas', data: {
        'local_id': localId,
        'fecha': fecha,
        'tipo': tipo,
        'entra': entra,
        'sale': sale,
        if (nota != null && nota.isNotEmpty) 'nota': nota,
      });
      return TurnoFecha.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> eliminarTurnoFecha(String profesionalId, String turnoFechaId) async {
    try {
      await _dio.delete('/profesionales/$profesionalId/turno-fechas/$turnoFechaId');
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Recursos ----

  Future<List<Recurso>> listarRecursos(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/recursos');
      return (res.data as List<dynamic>).map((e) => Recurso.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Recurso> crearRecurso(String localId, {required String tipo, required String nombre}) async {
    try {
      final res = await _dio.post('/locales/$localId/recursos', data: {'tipo': tipo, 'nombre': nombre});
      return Recurso.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> eliminarRecurso(String recursoId) async {
    try {
      await _dio.delete('/recursos/$recursoId');
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Habilidades ----

  Future<List<Habilidad>> listarHabilidades(String profesionalId) async {
    try {
      final res = await _dio.get('/profesionales/$profesionalId/habilidades');
      return (res.data as List<dynamic>)
          .map((e) => Habilidad.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Habilidad> crearHabilidad(
    String profesionalId, {
    required String servicioLocalId,
    double? precioOverride,
  }) async {
    try {
      final res = await _dio.post('/profesionales/$profesionalId/habilidades', data: {
        'servicio_local_id': servicioLocalId,
        'precio_override': precioOverride,
      });
      return Habilidad.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> eliminarHabilidad(String profesionalId, String habilidadId) async {
    try {
      await _dio.delete('/profesionales/$profesionalId/habilidades/$habilidadId');
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Excepciones ----

  Future<List<Excepcion>> listarExcepcionesLocal(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/excepciones');
      return _parseExcepciones(res.data);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<List<Excepcion>> listarExcepcionesProfesional(String profesionalId) async {
    try {
      final res = await _dio.get('/profesionales/$profesionalId/excepciones');
      return _parseExcepciones(res.data);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<List<Excepcion>> listarExcepcionesRecurso(String recursoId) async {
    try {
      final res = await _dio.get('/recursos/$recursoId/excepciones');
      return _parseExcepciones(res.data);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  List<Excepcion> _parseExcepciones(dynamic data) =>
      (data as List<dynamic>).map((e) => Excepcion.fromJson(e as Map<String, dynamic>)).toList();

  Future<Excepcion> crearExcepcion({
    required String origen, // 'locales' | 'profesionales' | 'recursos'
    required String origenId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String motivo,
    String? nota,
  }) async {
    try {
      final res = await _dio.post('/$origen/$origenId/excepciones', data: {
        'fecha_inicio': fechaInicio.toUtc().toIso8601String(),
        'fecha_fin': fechaFin.toUtc().toIso8601String(),
        'motivo': motivo,
        if (nota != null && nota.isNotEmpty) 'nota': nota,
      });
      return Excepcion.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> eliminarExcepcion(String excepcionId) async {
    try {
      await _dio.delete('/excepciones/$excepcionId');
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }
}
