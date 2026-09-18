import '../../data/models/directory_models.dart';
import '../../data/models/scheduling_models.dart';

/// Estado mutable del wizard de reserva (§5, §6). Vive en memoria durante
/// el flujo `local -> servicios -> slot -> confirmar -> hold`; no hace
/// falta persistirlo, es una sola sesión de navegación.
class BookingDraft {
  final LocalPerfilPublico local;
  Set<String> servicioIds;
  DateTime fecha;
  SlotDisponible? slot;
  String paraTipo;
  String? paraNombre;
  String? notaCliente;

  BookingDraft({
    required this.local,
    Set<String>? servicioIds,
    DateTime? fecha,
    this.slot,
    this.paraTipo = 'titular',
    this.paraNombre,
    this.notaCliente,
  })  : servicioIds = servicioIds ?? {},
        fecha = fecha ?? DateTime.now();

  double get precioTotal {
    var total = 0.0;
    for (final s in local.servicios) {
      if (servicioIds.contains(s.id)) {
        total += double.tryParse(s.precio) ?? 0;
      }
    }
    return total;
  }

  int get duracionTotalMin {
    var total = 0;
    for (final s in local.servicios) {
      if (servicioIds.contains(s.id)) {
        total += s.duracionMin;
      }
    }
    return total;
  }
}
