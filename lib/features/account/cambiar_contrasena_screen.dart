import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/repository_providers.dart';

/// Cambio de contraseña conociendo la actual (`PUT /cuenta/contrasena`).
class CambiarContrasenaScreen extends ConsumerStatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  ConsumerState<CambiarContrasenaScreen> createState() => _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends ConsumerState<CambiarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _cargando = false;
  bool _ver = false;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await ref.read(identityRepositoryProvider).cambiarContrasena(
            actual: _actualCtrl.text,
            nueva: _nuevaCtrl.text,
          );
      if (!mounted) return;
      mostrarMensaje(context, 'Contraseña actualizada.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final error = DioClient.mapearError(e);
      mostrarError(context, error.errorDe('actual') ?? error.errorDe('nueva') ?? error.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  InputDecoration _decoracion(String etiqueta) => InputDecoration(
        labelText: etiqueta,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_ver ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _ver = !_ver),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _actualCtrl,
              obscureText: !_ver,
              decoration: _decoracion('Contraseña actual'),
              validator: (v) => AppValidators.requerido(v, 'La contraseña actual'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nuevaCtrl,
              obscureText: !_ver,
              decoration: _decoracion('Contraseña nueva'),
              validator: AppValidators.password,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmarCtrl,
              obscureText: !_ver,
              decoration: _decoracion('Repite la contraseña nueva'),
              validator: (v) => v != _nuevaCtrl.text ? 'Las contraseñas no coinciden' : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Guardar contraseña', onPressed: _guardar, isLoading: _cargando, icon: Icons.check),
          ],
        ),
      ),
    );
  }
}
