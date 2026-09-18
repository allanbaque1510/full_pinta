import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../core/widgets/time_picker_field.dart';
import '../../data/models/directory_models.dart';
import '../../state/repository_providers.dart';

/// Horarios del local (§4.4) — varias filas por día permiten partir la
/// jornada (mañana/tarde).
class LocalHorariosScreen extends ConsumerStatefulWidget {
  final String localId;

  const LocalHorariosScreen({super.key, required this.localId});

  @override
  ConsumerState<LocalHorariosScreen> createState() => _LocalHorariosScreenState();
}

class _LocalHorariosScreenState extends ConsumerState<LocalHorariosScreen> {
  AsyncValue<List<HorarioLocal>> _horarios = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _horarios = const AsyncValue.loading());
    try {
      final lista = await ref.read(directoryRepositoryProvider).listarHorarios(widget.localId);
      if (mounted) setState(() => _horarios = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _horarios = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _crear() async {
    await showAppFormSheet(
      context,
      title: 'Nuevo horario',
      child: _HorarioForm(
        onGuardar: (dia, abre, cierra) async {
          try {
            await ref.read(directoryRepositoryProvider).crearHorario(widget.localId, diaSemana: dia, abre: abre, cierra: cierra);
            if (mounted) Navigator.of(context).pop();
            _cargar();
          } catch (e) {
            if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
          }
        },
      ),
    );
  }

  Future<void> _eliminar(HorarioLocal h) async {
    final ok = await confirmarDialogo(context, titulo: 'Eliminar horario', mensaje: 'Se borrará este bloque de horario.', destructivo: true);
    if (!ok) return;
    try {
      await ref.read(directoryRepositoryProvider).eliminarHorario(h.id);
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<HorarioLocal>(
      titulo: 'Horarios',
      items: _horarios,
      onRetry: _cargar,
      onCrear: _crear,
      mensajeVacio: 'Todavía no configuras horarios de atención.',
      iconoVacio: Icons.schedule_outlined,
      etiquetaContador: 'bloques de horario',
      itemBuilder: (context, h) => CrudTile(
        icono: Icons.schedule_outlined,
        titulo: nombresDias[h.diaSemana],
        subtitulo: '${h.abre} - ${h.cierra}',
        onEliminar: () => _eliminar(h),
      ),
    );
  }
}

class _HorarioForm extends StatefulWidget {
  final Future<void> Function(int dia, String abre, String cierra) onGuardar;

  const _HorarioForm({required this.onGuardar});

  @override
  State<_HorarioForm> createState() => _HorarioFormState();
}

class _HorarioFormState extends State<_HorarioForm> {
  int _dia = 1;
  TimeOfDay _abre = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _cierra = const TimeOfDay(hour: 19, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          value: _dia,
          decoration: const InputDecoration(labelText: 'Día'),
          items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text(nombresDias[i]))),
          onChanged: (v) => setState(() => _dia = v!),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TimePickerField(
                label: 'Hora apertura',
                valor: _abre,
                onChanged: (t) => setState(() => _abre = t),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TimePickerField(
                label: 'Hora cierre',
                valor: _cierra,
                onChanged: (t) => setState(() => _cierra = t),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormSubmitButton(
          onGuardar: () => widget.onGuardar(_dia, TimePickerField.formatear(_abre), TimePickerField.formatear(_cierra)),
        ),
      ],
    );
  }
}
