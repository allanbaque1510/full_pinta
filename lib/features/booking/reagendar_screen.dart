import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../data/models/directory_models.dart';
import '../../data/models/scheduling_models.dart';
import '../../state/repository_providers.dart';
import 'booking_draft.dart';
import 'hold_countdown_step.dart';
import 'slot_picker_step.dart';

/// Reagendar (§4.7) no es cancelar + crear: la cita vieja pasa a
/// `reagendada` y se crea una nueva enlazada por `reagendada_de_id`, con el
/// mismo camino optimista que agendar de cero. Reusa [SlotPickerStep] con
/// los mismos servicios de la cita original.
class ReagendarScreen extends ConsumerStatefulWidget {
  final Cita citaOriginal;

  const ReagendarScreen({super.key, required this.citaOriginal});

  @override
  ConsumerState<ReagendarScreen> createState() => _ReagendarScreenState();
}

class _ReagendarScreenState extends ConsumerState<ReagendarScreen> {
  LocalPerfilPublico? _local;
  Cita? _citaOriginal;
  bool _cargando = true;
  String? _error;
  Cita? _citaNueva;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// No confía en los `items` de la `Cita` recibida por navegación (puede
  /// venir de un contexto donde el shape sea más liviano) — vuelve a pedir
  /// la cita completa antes de armar el `BookingDraft`.
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final citaFuture = ref.read(schedulingRepositoryProvider).obtenerCita(widget.citaOriginal.id);
      final localFuture = ref.read(directoryRepositoryProvider).perfilPublicoLocal(widget.citaOriginal.localId);
      final cita = await citaFuture;
      final local = await localFuture;
      if (mounted) {
        setState(() {
          _citaOriginal = cita;
          _local = local;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final citaOriginal = _citaOriginal;
    if (_error != null || _local == null || citaOriginal == null || citaOriginal.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(mensaje: _error ?? 'No se pudo cargar la cita a reagendar.', onRetry: _cargar),
      );
    }
    if (_citaNueva != null) return HoldCountdownStep(cita: _citaNueva!);

    final draft = BookingDraft(
      local: _local!,
      servicioIds: citaOriginal.items.map((i) => i.servicioLocalId).toSet(),
    );

    return SlotPickerStep(
      draft: draft,
      mostrarProgreso: false,
      onAtras: () => Navigator.of(context).pop(),
      onSlotElegido: (slot) async {
        try {
          final nueva = await ref.read(schedulingRepositoryProvider).reagendar(
                widget.citaOriginal.id,
                profesionalId: slot.profesionalId,
                servicios: draft.servicioIds.toList(),
                inicio: slot.inicio,
                recursoId: slot.recursoId,
              );
          if (context.mounted) setState(() => _citaNueva = nueva);
        } catch (e) {
          if (context.mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
        }
      },
    );
  }
}
