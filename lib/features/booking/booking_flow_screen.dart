import 'package:flutter/material.dart';

import '../../data/models/directory_models.dart';
import '../../data/models/scheduling_models.dart';
import 'booking_confirm_step.dart';
import 'booking_draft.dart';
import 'hold_countdown_step.dart';
import 'seleccion_servicios_step.dart';
import 'slot_picker_step.dart';

/// Controlador del wizard de reserva. Cada paso es un widget propio (mismo
/// mapa de pantallas del plan); acá solo se decide cuál mostrar y se pasa
/// el [BookingDraft] compartido hacia adelante y atrás.
class BookingFlowScreen extends StatefulWidget {
  final LocalPerfilPublico local;

  const BookingFlowScreen({super.key, required this.local});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

enum _Paso { servicios, slot, confirmar, hold }

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  late final BookingDraft _draft = BookingDraft(local: widget.local);
  _Paso _paso = _Paso.servicios;
  Cita? _citaCreada;

  @override
  Widget build(BuildContext context) {
    switch (_paso) {
      case _Paso.servicios:
        return SeleccionServiciosStep(
          draft: _draft,
          onContinuar: () => setState(() => _paso = _Paso.slot),
        );
      case _Paso.slot:
        return SlotPickerStep(
          draft: _draft,
          onAtras: () => setState(() => _paso = _Paso.servicios),
          onSlotElegido: (slot) {
            _draft.slot = slot;
            setState(() => _paso = _Paso.confirmar);
          },
        );
      case _Paso.confirmar:
        return BookingConfirmStep(
          draft: _draft,
          onAtras: () => setState(() => _paso = _Paso.slot),
          onCitaCreada: (cita) {
            _citaCreada = cita;
            setState(() => _paso = _Paso.hold);
          },
        );
      case _Paso.hold:
        return HoldCountdownStep(cita: _citaCreada!);
    }
  }
}
