import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../models/catalog_models.dart';

class CatalogRepository {
  final Dio _dio;

  CatalogRepository({Dio? dio}) : _dio = dio ?? DioClient.instance;

  // ---- Catálogo maestro (público) ----

  Future<List<CategoriaServicio>> categorias({String? vertical}) async {
    try {
      final res = await _dio.get('/catalogo/categorias', queryParameters: {
        if (vertical != null) 'vertical': vertical,
      });
      return (res.data as List<dynamic>)
          .map((e) => CategoriaServicio.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<List<CatalogoServicio>> servicios({String? vertical, String? categoria}) async {
    try {
      final res = await _dio.get('/catalogo/servicios', queryParameters: {
        if (vertical != null) 'vertical': vertical,
        if (categoria != null) 'categoria': categoria,
      });
      return (res.data as List<dynamic>)
          .map((e) => CatalogoServicio.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Servicios del local ----

  Future<List<ServicioLocal>> listarServiciosLocal(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/servicios');
      return (res.data as List<dynamic>)
          .map((e) => ServicioLocal.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<ServicioLocal> crearServicioLocal(
    String localId, {
    required String catalogoServicioId,
    required double precio,
    bool precioDesde = false,
    required int duracionMin,
    int bufferMin = 0,
    bool comisionable = true,
  }) async {
    try {
      final res = await _dio.post('/locales/$localId/servicios', data: {
        'catalogo_servicio_id': catalogoServicioId,
        'precio': precio,
        'precio_desde': precioDesde,
        'duracion_min': duracionMin,
        'buffer_min': bufferMin,
        'comisionable': comisionable,
      });
      return ServicioLocal.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<ServicioLocal> actualizarServicioLocal(
    String servicioId, {
    double? precio,
    bool? precioDesde,
    int? duracionMin,
    int? bufferMin,
    bool? comisionable,
  }) async {
    try {
      final res = await _dio.patch('/servicios/$servicioId', data: {
        if (precio != null) 'precio': precio,
        if (precioDesde != null) 'precio_desde': precioDesde,
        if (duracionMin != null) 'duracion_min': duracionMin,
        if (bufferMin != null) 'buffer_min': bufferMin,
        if (comisionable != null) 'comisionable': comisionable,
      });
      return ServicioLocal.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> eliminarServicioLocal(String servicioId) async {
    try {
      await _dio.delete('/servicios/$servicioId');
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Productos ----

  Future<List<Producto>> listarProductos(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/productos');
      return (res.data as List<dynamic>).map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Producto> crearProducto(
    String localId, {
    required String nombre,
    required double precio,
    double comisionPct = 0,
  }) async {
    try {
      final res = await _dio.post('/locales/$localId/productos', data: {
        'nombre': nombre,
        'precio': precio,
        'comision_pct': comisionPct,
      });
      return Producto.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<Producto> actualizarProducto(
    String productoId, {
    String? nombre,
    double? precio,
    double? comisionPct,
  }) async {
    try {
      final res = await _dio.patch('/productos/$productoId', data: {
        if (nombre != null) 'nombre': nombre,
        if (precio != null) 'precio': precio,
        if (comisionPct != null) 'comision_pct': comisionPct,
      });
      return Producto.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<void> eliminarProducto(String productoId) async {
    try {
      await _dio.delete('/productos/$productoId');
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  // ---- Solicitudes al catálogo maestro ----

  Future<List<SolicitudCatalogo>> listarSolicitudes(String localId) async {
    try {
      final res = await _dio.get('/locales/$localId/solicitudes-catalogo');
      return (res.data as List<dynamic>)
          .map((e) => SolicitudCatalogo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }

  Future<SolicitudCatalogo> crearSolicitud(
    String localId, {
    required String vertical,
    required String nombrePropuesto,
    String? descripcion,
  }) async {
    try {
      final res = await _dio.post('/locales/$localId/solicitudes-catalogo', data: {
        'vertical': vertical,
        'nombre_propuesto': nombrePropuesto,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
      });
      return SolicitudCatalogo.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      throw DioClient.mapearError(e);
    }
  }
}
