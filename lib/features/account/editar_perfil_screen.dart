import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/repository_providers.dart';
import '../../state/session_controller.dart';

const _generos = {
  'm': 'Masculino',
  'f': 'Femenino',
  'otro': 'Otro',
  'no_decir': 'Prefiero no decirlo',
};

/// Edición del propio perfil (`PATCH /cuenta/perfil`). Teléfono y correo
/// no se editan aquí: tienen su propio flujo de verificación.
class EditarPerfilScreen extends ConsumerStatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _fotoCtrl;
  String? _genero;
  DateTime? _fechaNacimiento;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(sessionControllerProvider).usuario;
    _nombreCtrl = TextEditingController(text: u?.nombre ?? '');
    _fotoCtrl = TextEditingController(text: u?.fotoUrl ?? '');
    _genero = _generos.containsKey(u?.genero) ? u?.genero : null;
    _fechaNacimiento = u?.fechaNacimiento == null ? null : DateTime.tryParse(u!.fechaNacimiento!);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _fotoCtrl.dispose();
    super.dispose();
  }

  String _fechaIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(hoy.year - 25),
      firstDate: DateTime(1900),
      lastDate: hoy.subtract(const Duration(days: 1)),
    );
    if (elegida != null) setState(() => _fechaNacimiento = elegida);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final original = ref.read(sessionControllerProvider).usuario;
    final foto = _fotoCtrl.text.trim();
    setState(() => _cargando = true);
    try {
      final usuario = await ref.read(identityRepositoryProvider).actualizarPerfil(
            nombre: _nombreCtrl.text.trim(),
            genero: _genero,
            fechaNacimiento: _fechaNacimiento == null ? null : _fechaIso(_fechaNacimiento!),
            fotoUrl: foto.isEmpty ? null : foto,
            quitarFoto: foto.isEmpty && original?.fotoUrl != null,
          );
      ref.read(sessionControllerProvider.notifier).usuarioActualizado(usuario);
      if (!mounted) return;
      mostrarMensaje(context, 'Perfil actualizado.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final error = DioClient.mapearError(e);
      mostrarError(
        context,
        error.errorDe('nombre') ??
            error.errorDe('fecha_nacimiento') ??
            error.errorDe('foto_url') ??
            error.errorDe('genero') ??
            error.mensaje,
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fecha = _fechaNacimiento;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.badge_outlined)),
              validator: (v) => AppValidators.requerido(v, 'El nombre'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _genero,
              decoration: const InputDecoration(labelText: 'Género', prefixIcon: Icon(Icons.person_outline)),
              items: _generos.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _genero = v),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _elegirFecha,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                child: Text(
                  fecha == null
                      ? 'Sin definir'
                      : '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fotoCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL de la foto (vacío para quitarla)',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Guardar cambios', onPressed: _guardar, isLoading: _cargando, icon: Icons.check),
          ],
        ),
      ),
    );
  }
}
