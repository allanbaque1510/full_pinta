/// Configuración de la API.
///
/// Base URL editable en tiempo de build. Dos formas, misma variable:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2/full-pinta-api/public/api/v1
///   flutter run --dart-define-from-file=dart_defines.json   (recomendado, ver README)
///
/// `dart_defines.json` (gitignored, cada dev tiene el suyo) es también el
/// lugar donde van a futuro las credenciales que hoy no existen — API key
/// de Google Maps, client id de Google Sign-In — el día que se conecten
/// esos bloqueadores externos (ver plan de implementación). Ninguna va acá
/// todavía porque el código de esta primera versión no las usa.
///
/// El default apunta al setup local del equipo (Laragon/Apache sirviendo
/// Laravel en /full-pinta-api/public). Un emulador de Android NO puede
/// resolver "localhost" como el host de la máquina: ahí hay que pasar
/// API_BASE_URL=http://10.0.2.2/full-pinta-api/public/api/v1
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost/full-pinta-api/public/api/v1',
  );

  /// Zona horaria de presentación. La API entrega todo en UTC (§4.2);
  /// la conversión a hora local es responsabilidad del cliente.
  static const String zonaHoraria = 'America/Guayaquil';

  /// Duración del hold de una cita reservada (§5.4) — usado para pintar
  /// la cuenta regresiva sin depender de que el reloj del server llegue
  /// exacto en cada respuesta.
  static const Duration holdDuration = Duration(minutes: 10);

  // ---- Reservado para cuando se destraben los bloqueadores externos ----
  // (ver context/plan-implementacion.md, "Bloqueadores externos"). El
  // código de esta primera versión NO los lee todavía — google_maps_flutter
  // y google_sign_in ni siquiera están en pubspec.yaml. Están acá para que
  // exista un único lugar donde poner la key/el client id el día que se
  // consigan, en vez de inventarlo a mitad de una tarea futura.

  /// API key de Google Maps SDK (§12.2). Hoy la búsqueda es por lista, sin
  /// mapa embebido — ver `core/utils/location.dart` y "Ver en mapa" en el
  /// perfil del local, que abre la app de mapas del sistema sin necesitar key.
  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// OAuth client id de "Iniciar sesión con Google" (§4.3), uno por
  /// plataforma — Google los emite distintos para Web/Android/iOS.
  static const String googleOAuthClientIdWeb =
      String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID_WEB');
  static const String googleOAuthClientIdAndroid =
      String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID_ANDROID');
  static const String googleOAuthClientIdIos =
      String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID_IOS');
}
