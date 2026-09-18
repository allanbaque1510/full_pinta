import 'package:uuid/uuid.dart';

/// Genera claves de idempotencia (UUID v4) para los verbos que
/// `docs/api-referencia.md` marca explícitamente como "Idempotency-Key
/// obligatorio": agendar (crear cita, walk-in) y cancelar.
///
/// Una sola clave por intento lógico: si una pantalla reintenta el mismo
/// POST tras un timeout, debe reusar la misma clave (nunca generar una
/// nueva en el reintento), o el propósito del header se pierde.
class Idempotency {
  Idempotency._();

  static const _uuid = Uuid();

  static String nuevaClave() => _uuid.v4();
}
