import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

/// Sillas, mesas, tinas: una fila por unidad física (§4.6) — nunca una fila
/// con cantidad, o el constraint de exclusión de citas subvende o sobrevende.
class RecursosScreen extends ConsumerStatefulWidget {
  final String localId;

  const RecursosScreen({super.key, required this.localId});

  @override
  ConsumerState<RecursosScreen> createState() => _RecursosScreenState();
}

class _RecursosScreenState extends ConsumerState<RecursosScreen> {
  AsyncValue<List<Recurso>> _recursos = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _recursos = const AsyncValue.loading());
    try {
      final lista = await ref.read(staffingRepositoryProvider).listarRecursos(widget.localId);
      if (mounted) setState(() => _recursos = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _recursos = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _crear() async {
    await showAppFormSheet(
      context,
      title: 'Nuevo recurso',
      child: _RecursoForm(
        onGuardar: (tipo, nombre) async {
          try {
            await ref.read(staffingRepositoryProvider).crearRecurso(widget.localId, tipo: tipo, nombre: nombre);
            if (mounted) Navigator.of(context).pop();
            _cargar();
          } catch (e) {
            if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
          }
        },
      ),
    );
  }

  Future<void> _eliminar(Recurso r) async {
    final ok = await confirmarDialogo(context, titulo: 'Dar de baja', mensaje: 'Marca el recurso como fuera de servicio.', destructivo: true);
    if (!ok) return;
    try {
      await ref.read(staffingRepositoryProvider).eliminarRecurso(r.id);
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<Recurso>(
      titulo: 'Recursos',
      items: _recursos,
      onRetry: _cargar,
      onCrear: _crear,
      mensajeVacio: 'Sin sillas, mesas u otros recursos registrados.',
      iconoVacio: Icons.chair_outlined,
      itemBuilder: (context, r) => CrudTile(
        icono: Icons.chair_outlined,
        titulo: '${r.nombre}${r.activo ? '' : ' (fuera de servicio)'}',
        subtitulo: etiquetaTipoRecurso(r.tipo),
        onEliminar: r.activo ? () => _eliminar(r) : null,
      ),
    );
  }
}

class _RecursoForm extends StatefulWidget {
  final Future<void> Function(String tipo, String nombre) onGuardar;

  const _RecursoForm({required this.onGuardar});

  @override
  State<_RecursoForm> createState() => _RecursoFormState();
}

class _RecursoFormState extends State<_RecursoForm> {
  final _formKey = GlobalKey<FormState>();
  String _tipo = tiposRecurso.first;
  final _nombreCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: tiposRecurso.map((t) => DropdownMenuItem(value: t, child: Text(etiquetaTipoRecurso(t)))).toList(),
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre (ej. "Silla 3")'),
            validator: (v) => AppValidators.requerido(v, 'El nombre'),
          ),
          const SizedBox(height: 16),
          FormSubmitButton(
            formKey: _formKey,
            onGuardar: () => widget.onGuardar(_tipo, _nombreCtrl.text.trim()),
          ),
        ],
      ),
    );
  }
}
