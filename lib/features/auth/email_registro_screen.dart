import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/session_controller.dart';

class EmailRegistroScreen extends ConsumerStatefulWidget {
  const EmailRegistroScreen({super.key});

  @override
  ConsumerState<EmailRegistroScreen> createState() => _EmailRegistroScreenState();
}

class _EmailRegistroScreenState extends ConsumerState<EmailRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _cargando = false;
  bool _verPassword = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final sesion = await repo.registrarPorCorreo(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        telefono: _telefonoCtrl.text.trim(),
      );
      if (!mounted) return;
      mostrarMensaje(context, 'Cuenta creada. Verifica tu celular para completar el registro.');
      await ref.read(sessionControllerProvider.notifier).sesionIniciada(sesion.usuario);
    } catch (e) {
      if (!mounted) return;
      final error = DioClient.mapearError(e);
      mostrarError(
        context,
        error.errorDe('email') ?? error.errorDe('telefono') ?? error.errorDe('password') ?? error.mensaje,
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AuthScaffold(
      tituloHeader: 'Registro',
      etiquetaSuperior: 'Registro rápido',
      titulo: 'Crear cuenta',
      subtitulo: 'Únete a FullPinta y gestiona tus citas o tu negocio en Guayaquil.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => AppValidators.requerido(v, 'Tu nombre'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline)),
              validator: AppValidators.email,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Text('🇪🇨 +593', style: Theme.of(context).textTheme.labelLarge),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Número de celular', hintText: '09X XXX XXXX'),
                    validator: AppValidators.telefono,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: !_verPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Mínimo 8 caracteres',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _verPassword = !_verPassword),
                ),
              ),
              validator: AppValidators.password,
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Crear cuenta', onPressed: _registrar, isLoading: _cargando, icon: Icons.arrow_forward),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        children: [
                          TextSpan(
                            text: 'Nota: ',
                            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(
                            text:
                                'por seguridad de tu cuenta y para confirmaciones de reservas, verificarás tu celular con un código después de registrarte.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TrustRow(items: const [
              (Icons.lock_outline, 'Cifrado 256-bit'),
              (Icons.verified_outlined, 'Privacidad garantizada'),
            ]),
          ],
        ),
      ),
    );
  }
}
