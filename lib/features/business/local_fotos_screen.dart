import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../data/models/directory_models.dart';
import '../../state/repository_providers.dart';

const _tiposFoto = ['fachada', 'interior', 'trabajo'];

String _etiquetaTipoFoto(String t) => switch (t) {
      'fachada' => 'Fachada',
      'interior' => 'Interior',
      'trabajo' => 'Trabajo realizado',
      _ => t,
    };

/// La subida del archivo en sí no es parte de la API todavía (ver
/// `docs/api-referencia.md`): este formulario registra una URL ya subida a
/// algún storage externo, no sube el binario.
class LocalFotosScreen extends ConsumerStatefulWidget {
  final String localId;

  const LocalFotosScreen({super.key, required this.localId});

  @override
  ConsumerState<LocalFotosScreen> createState() => _LocalFotosScreenState();
}

class _LocalFotosScreenState extends ConsumerState<LocalFotosScreen> {
  AsyncValue<List<LocalFoto>> _fotos = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _fotos = const AsyncValue.loading());
    try {
      final lista = await ref.read(directoryRepositoryProvider).listarFotos(widget.localId);
      if (mounted) setState(() => _fotos = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _fotos = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _crear() async {
    await showAppFormSheet(
      context,
      title: 'Nueva foto',
      child: _FotoForm(
        onGuardar: (url, tipo) async {
          try {
            await ref.read(directoryRepositoryProvider).crearFoto(widget.localId, url: url, tipo: tipo);
            if (mounted) Navigator.of(context).pop();
            _cargar();
          } catch (e) {
            if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
          }
        },
      ),
    );
  }

  Future<void> _eliminar(LocalFoto foto) async {
    final ok = await confirmarDialogo(context, titulo: 'Eliminar foto', mensaje: '¿Quitar esta foto del local?', destructivo: true);
    if (!ok) return;
    try {
      await ref.read(directoryRepositoryProvider).eliminarFoto(foto.id);
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<LocalFoto>(
      titulo: 'Fotos',
      items: _fotos,
      onRetry: _cargar,
      onCrear: _crear,
      mensajeVacio: 'Todavía no subes fotos. Son el mejor gancho para que elijan tu local.',
      iconoVacio: Icons.photo_library_outlined,
      itemBuilder: (context, f) => CrudTile(
        icono: Icons.image_outlined,
        titulo: _etiquetaTipoFoto(f.tipo),
        subtitulo: f.url,
        onEliminar: () => _eliminar(f),
      ),
    );
  }
}

class _FotoForm extends StatefulWidget {
  final Future<void> Function(String url, String tipo) onGuardar;

  const _FotoForm({required this.onGuardar});

  @override
  State<_FotoForm> createState() => _FotoFormState();
}

class _FotoFormState extends State<_FotoForm> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  String _tipo = 'fachada';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _urlCtrl,
            decoration: const InputDecoration(labelText: 'URL de la foto'),
            validator: (v) => AppValidators.requerido(v, 'La URL'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _tipo,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: _tiposFoto.map((t) => DropdownMenuItem(value: t, child: Text(_etiquetaTipoFoto(t)))).toList(),
            onChanged: (v) => setState(() => _tipo = v!),
          ),
          const SizedBox(height: 16),
          FormSubmitButton(
            formKey: _formKey,
            onGuardar: () => widget.onGuardar(_urlCtrl.text.trim(), _tipo),
          ),
        ],
      ),
    );
  }
}
