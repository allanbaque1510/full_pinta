import 'package:intl/intl.dart';

/// La API entrega todo en UTC (§4.2 de la especificación); Ecuador
/// continental es un solo huso, UTC-5, sin horario de verano — así que
/// convertir es una resta fija de 5 horas, sin necesitar el paquete
/// `timezone` completo.
const _offsetGuayaquil = Duration(hours: 5);

class AppFormatters {
  AppFormatters._();

  static DateTime aGuayaquil(DateTime utc) => utc.toUtc().subtract(_offsetGuayaquil);

  static DateTime aUtcDesdeGuayaquil(DateTime local) =>
      local.add(_offsetGuayaquil).toUtc();

  static final _fechaHora = DateFormat("EEEE d 'de' MMMM, HH:mm", 'es');
  static final _fecha = DateFormat("EEEE d 'de' MMMM", 'es');
  static final _fechaCorta = DateFormat('dd/MM/yyyy', 'es');
  static final _hora = DateFormat('HH:mm', 'es');
  static final _fechaIso = DateFormat('yyyy-MM-dd');

  static String fechaHoraLegible(DateTime utc) => _capitalizar(_fechaHora.format(aGuayaquil(utc)));

  static String fechaLegible(DateTime utc) => _capitalizar(_fecha.format(aGuayaquil(utc)));

  static String fechaCorta(DateTime utc) => _fechaCorta.format(aGuayaquil(utc));

  static String horaLegible(DateTime utc) => _hora.format(aGuayaquil(utc));

  static String fechaIso(DateTime fechaLocal) => _fechaIso.format(fechaLocal);

  static String _capitalizar(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// `precio` viaja como string ("8.50") desde la API — es un numeric(10,2)
  /// de Postgres, así evita el redondeo binario de los floats (ver
  /// api-referencia.md, sección Servicios del local).
  static String dinero(String? valorNumericString) {
    final valor = double.tryParse(valorNumericString ?? '0') ?? 0;
    return '\$${valor.toStringAsFixed(2)}';
  }

  static String dineroNum(num valor) => '\$${valor.toStringAsFixed(2)}';

  static String distancia(double metros) {
    if (metros < 1000) return '${metros.round()} m';
    return '${(metros / 1000).toStringAsFixed(1)} km';
  }

  static String duracion(int minutos) {
    if (minutos < 60) return '$minutos min';
    final horas = minutos ~/ 60;
    final resto = minutos % 60;
    return resto == 0 ? '${horas}h' : '${horas}h $resto min';
  }

  /// "En 2 horas" / "Mañana" / "Hace 3 días" — para el countdown de un hold
  /// o el resumen de una cita, sin depender de un paquete de i18n aparte.
  static String tiempoRelativo(DateTime utc) {
    final ahora = DateTime.now().toUtc();
    final diferencia = utc.toUtc().difference(ahora);
    final futuro = !diferencia.isNegative;
    final abs = diferencia.abs();

    if (abs.inMinutes < 1) return futuro ? 'Ahora mismo' : 'Recién';
    if (abs.inMinutes < 60) {
      return futuro ? 'En ${abs.inMinutes} min' : 'Hace ${abs.inMinutes} min';
    }
    if (abs.inHours < 24) {
      return futuro ? 'En ${abs.inHours} h' : 'Hace ${abs.inHours} h';
    }
    if (abs.inDays == 1) return futuro ? 'Mañana' : 'Ayer';
    if (abs.inDays < 7) {
      return futuro ? 'En ${abs.inDays} días' : 'Hace ${abs.inDays} días';
    }
    return fechaCorta(utc);
  }
}
