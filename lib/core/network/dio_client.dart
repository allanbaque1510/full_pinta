import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

/// Cliente Dio único de la app: agrega el header `Authorization: Bearer`
/// automáticamente cuando hay token guardado, y traduce cualquier
/// `DioException` a [ApiException] con el shape que documenta
/// `docs/api-referencia.md`, para que las pantallas nunca toquen Dio directo.
class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _build();
    return _instance!;
  }

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        // Dejamos que las respuestas 4xx/5xx lleguen como Response normal
        // para poder mapear el shape de error del backend nosotros mismos.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.leerToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.statusCode != null && response.statusCode! >= 400) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              ),
              true,
            );
            return;
          }
          handler.next(response);
        },
      ),
    );

    return dio;
  }

  /// Convierte cualquier excepción salida de una llamada Dio a [ApiException].
  static ApiException mapearError(Object error) {
    if (error is ApiException) return error;

    if (error is! DioException) {
      return ApiException(mensaje: 'Ocurrió un error inesperado: $error');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          mensaje: 'El servidor tardó demasiado en responder. Intenta de nuevo.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          mensaje: 'No se pudo conectar con el servidor. Revisa tu conexión.',
        );
      case DioExceptionType.cancel:
        return const ApiException(mensaje: 'Solicitud cancelada.');
      case DioExceptionType.badResponse:
        return _mapearRespuesta(error);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      default:
        return ApiException(mensaje: 'Ocurrió un error inesperado: ${error.message}');
    }
  }

  static ApiException _mapearRespuesta(DioException error) {
    final response = error.response;
    final status = response?.statusCode;
    final data = response?.data;

    int? retryAfter;
    final retryHeader = response?.headers.value('Retry-After');
    if (retryHeader != null) retryAfter = int.tryParse(retryHeader);

    if (status == 401) {
      return const ApiException(
        statusCode: 401,
        mensaje: 'Tu sesión expiró. Vuelve a iniciar sesión.',
      );
    }

    if (data is Map<String, dynamic>) {
      // 422 estándar de Laravel: { message, errors: { campo: [..] } }
      if (data['errors'] is Map) {
        final erroresRaw = data['errors'] as Map;
        final errores = erroresRaw.map(
          (key, value) => MapEntry(
            key.toString(),
            (value as List).map((e) => e.toString()).toList(),
          ),
        );
        return ApiException(
          statusCode: status,
          mensaje: data['message']?.toString() ?? 'Hay datos inválidos en el formulario.',
          errores: errores,
          retryAfterSeconds: retryAfter,
        );
      }

      // Error de negocio: { codigo, mensaje, ...campos propios }
      if (data['codigo'] != null || data['mensaje'] != null) {
        return ApiException(
          statusCode: status,
          codigo: data['codigo']?.toString(),
          mensaje: data['mensaje']?.toString() ?? 'Ocurrió un error.',
          retryAfterSeconds: retryAfter,
        );
      }

      if (data['message'] != null) {
        return ApiException(
          statusCode: status,
          mensaje: data['message'].toString(),
          retryAfterSeconds: retryAfter,
        );
      }
    }

    return ApiException(
      statusCode: status,
      mensaje: 'Ocurrió un error (${status ?? 'sin conexión'}).',
      retryAfterSeconds: retryAfter,
    );
  }
}
