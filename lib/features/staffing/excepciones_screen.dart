import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

enum OrigenExcepcion { local, profesional, recurso }

/// Cierres y ausencias (§4.6): de un local, un profesional (bloquea TODOS
/// sus locales, no solo uno) o un recurso. Misma forma en los tres
/// orígenes — una sola pantalla parametrizada en vez de tres casi iguales.
class ExcepcionesScreen extends ConsumerStatefulWidget {
  final OrigenExcepcion origen;
  final String origenId;
  final String titulo;

  const ExcepcionesScreen({super.key, required this.origen, required this.origenId, required this.titulo});

  @override
  ConsumerState<ExcepcionesScreen> createState() => _ExcepcionesScreenState();
}

extension on OrigenExcepcion {
  String get segmentoRuta => switch (this) {
        OrigenExcepcion.local => 'locales',
        OrigenExcepcion.profesional => 'profesionales',
        OrigenExcepcion.recurso => 'recursos',
      };
}

class _ExcepcionesScreenState extends ConsumerState<ExcepcionesScreen> {
  AsyncValue<List<Excepcion>> _excepciones = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _excepciones = const AsyncValue.loading());
    try {
      final repo = ref.read(staffingRepositoryProvider);
      final lista = switch (widget.origen) {
        OrigenExcepcion.local => await repo.listarExcepcionesLocal(widget.origenId),
        OrigenExcepcion.profesional => await repo.listarExcepcionesProfesional(widget.origenId),
        OrigenExcepcion.recurso => await repo.listarExcepcionesRecurso(widget.origenId),
      };
      if (mounted) setState(() => _excepciones = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _excepciones = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _crear() async {
    await showAppFormSheet(
      context,
      title: 'Nuevo bloqueo',
      child: _ExcepcionForm(
        onGuardar: (inicio, fin, motivo, nota) async {
          try {
            await ref.read(staffingRepositoryProvider).crearExcepcion(
                  origen: widget.origen.segmentoRuta,
                  origenId: widget.origenId,
                  fechaInicio: inicio,
                  fechaFin: fin,
                  motivo: motivo,
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

  Future<void> _eliminar(Excepcion e) async {
    final ok = await confirmarDialogo(context, titulo: 'Quitar bloqueo', mensaje: 'Se libera esta ventana de tiempo.', destructivo: true);
    if (!ok) return;
    try {
      await ref.read(staffingRepositoryProvider).eliminarExcepcion(e.id);
      _cargar();
    } catch (err) {
      if (mounted) mostrarError(context, DioClient.mapearError(err).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<Excepcion>(
      titulo: widget.titulo,
      items: _excepciones,
      onRetry: _cargar,
      onCrear: _crear,
      mensajeVacio: 'Sin cierres ni ausencias registradas.',
      iconoVacio: Icons.event_busy_outlined,
      itemBuilder: (context, e) => CrudTile(
        icono: Icons.event_busy_outlined,
        titulo: etiquetaMotivoExcepcion(e.motivo),
        subtitulo: '${AppFormatters.fechaHoraLegible(e.fechaInicio)} → ${AppFormatters.fechaHoraLegible(e.fechaFin)}',
        onEliminar: () => _eliminar(e),
      ),
    );
  }
}

class _ExcepcionForm extends StatefulWidget {
  final Future<void> Function(DateTime inicio, DateTime fin, String motivo, String? nota) onGuardar;

  const _ExcepcionForm({required this.onGuardar});

  @override
  State<_ExcepcionForm> createState() => _ExcepcionFormState();
}

class _ExcepcionFormState extends State<_ExcepcionForm> {
  DateTime _inicio = DateTime.now();
  DateTime _fin = DateTime.now().add(const Duration(hours: 8));
  String _motivo = motivosExcepcion.first;
  final _notaCtrl = TextEditingController();

  Future<void> _elegir(bool esInicio) async {
    final base = esInicio ? _inicio : _fin;
    final fecha = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(base));
    if (hora == null) return;
    final resultado = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
    setState(() {
      if (esInicio) {
        _inicio = resultado;
      } else {
        _fin = resultado;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _motivo,
          decoration: const InputDecoration(labelText: 'Motivo'),
          items: motivosExcepcion.map((m) => DropdownMenuItem(value: m, child: Text(etiquetaMotivoExcepcion(m)))).toList(),
          onChanged: (v) => setState(() => _motivo = v!),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Desde'),
          trailing: Text(AppFormatters.fechaHoraLegible(_inicio.toUtc())),
          onTap: () => _elegir(true),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hasta'),
          trailing: Text(AppFormatters.fechaHoraLegible(_fin.toUtc())),
          onTap: () => _elegir(false),
        ),
        TextField(controller: _notaCtrl, decoration: const InputDecoration(labelText: 'Nota (opcional)')),
        const SizedBox(height: 16),
        FormSubmitButton(
          onGuardar: () => widget.onGuardar(_inicio, _fin, _motivo, _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim()),
        ),
      ],
    );
  }
}
