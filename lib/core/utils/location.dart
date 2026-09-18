import 'package:geolocator/geolocator.dart';

/// Centro de Guayaquil — fallback si el usuario niega el permiso de
/// ubicación o el dispositivo no lo soporta. La v1 lanza en una sola zona
/// geográfica (§2), así que un fallback fijo a esa ciudad es razonable.
class LatLng {
  final double lat;
  final double lng;

  const LatLng(this.lat, this.lng);
}

const guayaquilFallback = LatLng(-2.1894, -79.8891);

class AppLocation {
  AppLocation._();

  static Future<LatLng> obtenerUbicacionActual() async {
    try {
      final habilitado = await Geolocator.isLocationServiceEnabled();
      if (!habilitado) return guayaquilFallback;

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        return guayaquilFallback;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
      return LatLng(posicion.latitude, posicion.longitude);
    } catch (_) {
      return guayaquilFallback;
    }
  }
}
