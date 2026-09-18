import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../models/directory_models.dart';

class DirectoryRepository {
  final Dio _dio;

  DirectoryRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  // ---- Negocio ----

  Future<Negocio> crearNegocio({required String nombreMarca, String? ruc}) async {
    try {
      final res = await _dio.post('/negocios', data: {
        'nombre_marca': nombreMarca,
        if (ruc != null && ruc.isNotEmpty) 'ruc': ruc,
      });
      return Negocio.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Negocio> obtenerNegocio(String negocioId) async {
    try {
      final res = await _dio.get('/negocios/$negocioId');
      return Negocio.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Negocio> actualizarNegocio(String negocioId, {String? nombreMarca, String? ruc}) async {
    try {
      final res = await _dio.patch('/negocios/$negocioId', data: {
        if (nombreMarca != null) 'nombre_marca': nombreMarca,
        if (ruc != null) 'ruc': ruc,
      });
      return Negocio.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Local ----

  Future<List<Local>> listarLocales(String negocioId) async {
    try {
      final res = await _dio.get('/negocios/$negocioId/locales');
      return (res.data as List<dynamic>).map((e) => Local.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Local> crearLocal(
    String negocioId, {
    required String nombre,
    required String direccion,
    String? referencia,
    required double lat,
    required double lng,
    String? telefono,
    String? whatsapp,
  }) async {
    try {
      final res = await _dio.post('/negocios/$negocioId/locales', data: {
        'nombre': nombre,
        'direccion': direccion,
        if (referencia != null && referencia.isNotEmpty) 'referencia': referencia,
        'lat': lat,
        'lng': lng,
        if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
        if (whatsapp != null && whatsapp.isNotEmpty) 'whatsapp': whatsapp,
      });
      return Local.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Local> obtenerLocal(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId');
      return Local.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Local> actualizarLocal(
    String localId, {
    String? nombre,
    String? direccion,
    String? referencia,
    double? lat,
    double? lng,
    String? telefono,
    String? whatsapp,
  }) async {
    try {
      final res = await _dio.patch('/locales/$localId', data: {
        if (nombre != null) 'nombre': nombre,
        if (direccion != null) 'direccion': direccion,
        if (referencia != null) 'referencia': referencia,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (telefono != null) 'telefono': telefono,
        if (whatsapp != null) 'whatsapp': whatsapp,
      });
      return Local.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Local> activarLocal(String localId) async {
    try {
      final res = await _dio.post('/locales/$localId/activar');
      return Local.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Local> pausarLocal(String localId) async {
    try {
      final res = await _dio.post('/locales/$localId/pausar');
      return Local.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Horarios ----

  Future<List<HorarioLocal>> listarHorarios(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/horarios');
      return (res.data as List<dynamic>)
          .map((e) => HorarioLocal.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<HorarioLocal> crearHorario(
    String localId, {
    required int diaSemana,
    required String abre,
    required String cierra,
  }) async {
    try {
      final res = await _dio.post('/locales/$localId/horarios', data: {
        'dia_semana': diaSemana,
        'abre': abre,
        'cierra': cierra,
      });
      return HorarioLocal.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<HorarioLocal> actualizarHorario(
    String horarioId, {
    int? diaSemana,
    String? abre,
    String? cierra,
  }) async {
    try {
      final res = await _dio.patch('/horarios/$horarioId', data: {
        if (diaSemana != null) 'dia_semana': diaSemana,
        if (abre != null) 'abre': abre,
        if (cierra != null) 'cierra': cierra,
      });
      return HorarioLocal.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> eliminarHorario(String horarioId) async {
    try {
      await _dio.delete('/horarios/$horarioId');
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Amenidades ----

  Future<List<Amenidad>> catalogoAmenidades({String? categoria}) async {
    try {
      final res = await _dio.get('/amenidades', queryParameters: {
        if (categoria != null) 'categoria': categoria,
      });
      return (res.data as List<dynamic>).map((e) => Amenidad.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<List<Amenidad>> amenidadesDelLocal(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/amenidades');
      return (res.data as List<dynamic>).map((e) => Amenidad.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  /// Reemplaza el conjunto completo (nunca agrega/quita una por una).
  Future<List<Amenidad>> sincronizarAmenidades(
    String localId,
    List<Map<String, dynamic>> amenidades,
  ) async {
    try {
      final res = await _dio.put('/locales/$localId/amenidades', data: {'amenidades': amenidades});
      return (res.data as List<dynamic>).map((e) => Amenidad.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Fotos ----

  Future<List<LocalFoto>> listarFotos(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/fotos');
      return (res.data as List<dynamic>).map((e) => LocalFoto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<LocalFoto> crearFoto(
    String localId, {
    required String url,
    required String tipo,
    int orden = 0,
  }) async {
    try {
      final res = await _dio.post('/locales/$localId/fotos', data: {
        'url': url,
        'tipo': tipo,
        'orden': orden,
      });
      return LocalFoto.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> eliminarFoto(String fotoId) async {
    try {
      await _dio.delete('/fotos/$fotoId');
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Búsqueda y perfil público ----

  Future<List<LocalBusqueda>> buscarLocales({
    required double lat,
    required double lng,
    int radioM = 20000,
    String? vertical,
    String? catalogoServicioId,
    double? precioMin,
    double? precioMax,
    List<String>? amenidades,
    bool? disponible,
    String? fecha,
    bool? abiertoAhora,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get('/buscar/locales', queryParameters: {
        'lat': lat,
        'lng': lng,
        'radio_m': radioM,
        if (vertical != null) 'vertical': vertical,
        if (catalogoServicioId != null) 'catalogo_servicio_id': catalogoServicioId,
        if (precioMin != null) 'precio_min': precioMin,
        if (precioMax != null) 'precio_max': precioMax,
        if (amenidades != null && amenidades.isNotEmpty) 'amenidades[]': amenidades,
        if (disponible != null) 'disponible': disponible,
        if (fecha != null) 'fecha': fecha,
        if (abiertoAhora != null) 'abierto_ahora': abiertoAhora,
        'page': page,
      });
      return (res.data as List<dynamic>)
          .map((e) => LocalBusqueda.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<LocalPerfilPublico> perfilPublicoLocal(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/perfil-publico');
      return LocalPerfilPublico.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }
}
