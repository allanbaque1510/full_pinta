import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../core/widgets/time_picker_field.dart';
import '../../data/models/directory_models.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

/// Horario semanal recurrente de una asignación (§4.6). Postgres es la
/// única fuente de verdad contra traslapes — un 422 acá casi siempre
/// significa que el profesional ya tiene otro turno encimado, en este local
/// o en otro.
class AsignacionTurnosScreen extends ConsumerStatefulWidget {
  final String asignacionId;

  const AsignacionTurnosScreen({super.key, required this.asignacionId});

  @override
  ConsumerState<AsignacionTurnosScreen> createState() => _AsignacionTurnosScreenState();
}

class _AsignacionTurnosScreenState extends ConsumerState<AsignacionTurnosScreen> {
  AsyncValue<List<Turno>> _turnos = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _turnos = const AsyncValue.loading());
    try {
      final lista = await ref.read(staffingRepositoryProvider).listarTurnos(widget.asignacionId);
      if (mounted) setState(() => _turnos = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _turnos = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _crear() async {
    await showAppFormSheet(
      context,
      title: 'Nuevo turno',
      child: _TurnoForm(
        onGuardar: (dia, entra, sale, desde) async {
          try {
            await ref.read(staffingRepositoryProvider).crearTurno(
                  widget.asignacionId,
                  diaSemana: dia,
                  entra: entra,
                  sale: sale,
                  vigenteDesde: desde,
                );
            if (mounted) Navigator.of(context).pop();
            _cargar();
          } catch (e) {
            if (mounted) mostrarError(context, DioClient.mapearError(e).errorDe('entra') ?? DioClient.mapearError(e).mensaje);
          }
        },
      ),
    );
  }

  Future<void> _eliminar(Turno t) async {
    final ok = await confirmarDialogo(context, titulo: 'Eliminar turno', mensaje: 'Se borra este bloque del horario.', destructivo: true);
    if (!ok) return;
    try {
      await ref.read(staffingRepositoryProvider).eliminarTurno(t.id);
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<Turno>(
      titulo: 'Turnos',
      items: _turnos,
      onRetry: _cargar,
      onCrear: _crear,
      mensajeVacio: 'Sin turnos configurados todavía.',
      iconoVacio: Icons.schedule_outlined,
      itemBuilder: (context, t) => CrudTile(
        icono: Icons.schedule_outlined,
        titulo: nombresDias[t.diaSemana],
        subtitulo: '${t.entra} - ${t.sale}',
        onEliminar: () => _eliminar(t),
      ),
    );
  }
}

class _TurnoForm extends StatefulWidget {
  final Future<void> Function(int dia, String entra, String sale, String vigenteDesde) onGuardar;

  const _TurnoForm({required this.onGuardar});

  @override
  State<_TurnoForm> createState() => _TurnoFormState();
}

class _TurnoFormState extends State<_TurnoForm> {
  int _dia = 1;
  TimeOfDay _entra = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _sale = const TimeOfDay(hour: 18, minute: 0);
  DateTime _vigenteDesde = DateTime.now();

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
            Expanded(child: TimePickerField(label: 'Entra', valor: _entra, onChanged: (t) => setState(() => _entra = t))),
            const SizedBox(width: 12),
            Expanded(child: TimePickerField(label: 'Sale', valor: _sale, onChanged: (t) => setState(() => _sale = t))),
          ],
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Vigente desde'),
          trailing: Text(AppFormatters.fechaCorta(_vigenteDesde.toUtc())),
          onTap: () async {
            final f = await showDatePicker(
              context: context,
              initialDate: _vigenteDesde,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (f != null) setState(() => _vigenteDesde = f);
          },
        ),
        const SizedBox(height: 16),
        FormSubmitButton(
          onGuardar: () => widget.onGuardar(
            _dia,
            TimePickerField.formatear(_entra),
            TimePickerField.formatear(_sale),
            AppFormatters.fechaIso(_vigenteDesde),
          ),
        ),
      ],
    );
  }
}
