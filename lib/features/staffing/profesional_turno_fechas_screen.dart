import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../core/widgets/time_picker_field.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

/// Overrides puntuales sobre el turno recurrente (§4.6): "este sábado no
/// voy a Urdesa, voy a Alborada" — no modifica el turno base.
class ProfesionalTurnoFechasScreen extends ConsumerStatefulWidget {
  final String profesionalId;
  final String localId;

  const ProfesionalTurnoFechasScreen({super.key, required this.profesionalId, required this.localId});

  @override
  ConsumerState<ProfesionalTurnoFechasScreen> createState() => _ProfesionalTurnoFechasScreenState();
}

class _ProfesionalTurnoFechasScreenState extends ConsumerState<ProfesionalTurnoFechasScreen> {
  AsyncValue<List<TurnoFecha>> _fechas = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _fechas = const AsyncValue.loading());
    try {
      final lista = await ref.read(staffingRepositoryProvider).listarTurnoFechas(widget.profesionalId);
      if (mounted) setState(() => _fechas = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _fechas = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _crear() async {
    await showAppFormSheet(
      context,
      title: 'Cambio de turno por fecha',
      child: _TurnoFechaForm(
        onGuardar: (fecha, tipo, entra, sale, nota) async {
          try {
            await ref.read(staffingRepositoryProvider).crearTurnoFecha(
                  widget.profesionalId,
                  localId: widget.localId,
                  fecha: fecha,
                  tipo: tipo,
                  entra: entra,
                  sale: sale,
                  nota: nota,
                );
            if (mounted) Navigator.of(context).pop();
            _cargar();
          } catch (e) {
            if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
          }
        },
      ),
    );
  }

  Future<void> _eliminar(TurnoFecha t) async {
    final ok = await confirmarDialogo(context, titulo: 'Eliminar cambio', mensaje: 'Se quita este cambio puntual.', destructivo: true);
    if (!ok) return;
    try {
      await ref.read(staffingRepositoryProvider).eliminarTurnoFecha(widget.profesionalId, t.id);
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<TurnoFecha>(
      titulo: 'Cambios por fecha',
      items: _fechas,
      onRetry: _cargar,
      onCrear: _crear,
      mensajeVacio: 'Sin cambios puntuales registrados.',
      iconoVacio: Icons.event_repeat_outlined,
      itemBuilder: (context, t) => CrudTile(
        icono: Icons.event_repeat_outlined,
        titulo: t.fecha,
        subtitulo: t.tipo == 'cancela' ? 'Cancela su turno normal' : '${_etiquetaTipo(t.tipo)}: ${t.entra} - ${t.sale}',
        onEliminar: () => _eliminar(t),
      ),
    );
  }

  String _etiquetaTipo(String tipo) => tipo == 'extra' ? 'Turno extra' : 'Reemplaza el turno';
}

class _TurnoFechaForm extends StatefulWidget {
  final Future<void> Function(String fecha, String tipo, String? entra, String? sale, String? nota) onGuardar;

  const _TurnoFechaForm({required this.onGuardar});

  @override
  State<_TurnoFechaForm> createState() => _TurnoFechaFormState();
}

class _TurnoFechaFormState extends State<_TurnoFechaForm> {
  DateTime _fecha = DateTime.now();
  String _tipo = 'extra';
  TimeOfDay _entra = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _sale = const TimeOfDay(hour: 18, minute: 0);
  final _notaCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final esCancela = _tipo == 'cancela';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fecha'),
          trailing: Text(AppFormatters.fechaCorta(_fecha.toUtc())),
          onTap: () async {
            final f = await showDatePicker(
              context: context,
              initialDate: _fecha,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (f != null) setState(() => _fecha = f);
          },
        ),
        DropdownButtonFormField<String>(
          value: _tipo,
          decoration: const InputDecoration(labelText: 'Tipo'),
          items: tiposTurnoFecha
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t == 'extra' ? 'Turno extra' : t == 'reemplaza' ? 'Reemplaza el turno' : 'Cancela'),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _tipo = v!),
        ),
        if (!esCancela) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TimePickerField(label: 'Entra', valor: _entra, onChanged: (t) => setState(() => _entra = t))),
              const SizedBox(width: 12),
              Expanded(child: TimePickerField(label: 'Sale', valor: _sale, onChanged: (t) => setState(() => _sale = t))),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _notaCtrl,
          decoration: const InputDecoration(labelText: 'Nota (opcional)'),
        ),
        const SizedBox(height: 16),
        FormSubmitButton(
          onGuardar: () => widget.onGuardar(
            AppFormatters.fechaIso(_fecha),
            _tipo,
            esCancela ? null : TimePickerField.formatear(_entra),
            esCancela ? null : TimePickerField.formatear(_sale),
            _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
          ),
        ),
      ],
    );
  }
}
