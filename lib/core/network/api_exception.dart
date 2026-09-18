/// Representa un error de la API tal como lo documenta `docs/api-referencia.md`:
/// negocio (`{codigo, mensaje}`), validación 422 (`{message, errors}`) o de
/// transporte (sin conexión, timeout).
class ApiException implements Exception {
  final int? statusCode;

  /// `codigo` estable de un error de negocio (ej. `slot_ya_ocupado`,
  /// `otp_incorrecto`). Null si es un error de validación estándar o de red.
  final String? codigo;

  /// Mensaje para mostrar al usuario.
  final String mensaje;

  /// Errores de validación por campo (`{ "campo": ["mensaje"] }`), si aplica.
  final Map<String, List<String>>? errores;

  /// Segundos de espera sugeridos (header `Retry-After` en 429).
  final int? retryAfterSeconds;

  const ApiException({
    required this.mensaje,
    this.statusCode,
    this.codigo,
    this.errores,
    this.retryAfterSeconds,
  });

  bool get esValidacion => errores != null && errores!.isNotEmpty;

  bool get esRateLimit => statusCode == 429;

  bool get esConflicto => statusCode == 409;

  bool get esNoAutorizado => statusCode == 401 || statusCode == 403;

  bool get esNoEncontrado => statusCode == 404;

  /// Primer mensaje de error de un campo específico, si existe.
  String? errorDe(String campo) => errores?[campo]?.first;

  @override
  String toString() => mensaje;
}
