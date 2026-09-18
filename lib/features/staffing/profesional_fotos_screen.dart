import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

/// El portafolio del profesional (§4.6) — la gente escoge barbero viendo
/// cortes, no leyendo precios.
class ProfesionalFotosScreen extends ConsumerStatefulWidget {
  final String profesionalId;

  const ProfesionalFotosScreen({super.key, required this.profesionalId});

  @override
  ConsumerState<ProfesionalFotosScreen> createState() => _ProfesionalFotosScreenState();
}

class _ProfesionalFotosScreenState extends ConsumerState<ProfesionalFotosScreen> {
  AsyncValue<List<ProfesionalFoto>> _fotos = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _fotos = const AsyncValue.loading());
    try {
      final lista = await ref.read(staffingRepositoryProvider).listarFotosProfesional(widget.profesionalId);
      if (mounted) setState(() => _fotos = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _fotos = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _crear() async {
    final urlCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var guardando = false;
    await showAppFormSheet(
      context,
      title: 'Nueva foto',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'URL de la foto'),
                validator: (v) => AppValidators.requerido(v, 'La URL'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Guardar',
                isLoading: guardando,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  setSheetState(() => guardando = true);
                  try {
                    await ref
                        .read(staffingRepositoryProvider)
                        .crearFotoProfesional(widget.profesionalId, url: urlCtrl.text.trim());
                    if (context.mounted) Navigator.of(context).pop();
                    _cargar();
                  } catch (e) {
                    if (context.mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
                    setSheetState(() => guardando = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _eliminar(ProfesionalFoto f) async {
    final ok = await confirmarDialogo(context, titulo: 'Eliminar foto', mensaje: '¿Quitar esta foto del portafolio?', destructivo: true);
    if (!ok) return;
    try {
      await ref.read(staffingRepositoryProvider).eliminarFotoProfesional(widget.profesionalId, f.id);
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<ProfesionalFoto>(
      titulo: 'Fotos de trabajos',
      items: _fotos,
      onRetry: _cargar,
      onCrear: _crear,
      mensajeVacio: 'El portafolio es el mejor mecanismo de descubrimiento: súbele fotos.',
      iconoVacio: Icons.photo_library_outlined,
      itemBuilder: (context, f) => CrudTile(icono: Icons.image_outlined, titulo: f.url, onEliminar: () => _eliminar(f)),
    );
  }
}
