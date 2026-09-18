import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/session_controller.dart';

class OtpSolicitarScreen extends ConsumerStatefulWidget {
  const OtpSolicitarScreen({super.key});

  @override
  ConsumerState<OtpSolicitarScreen> createState() => _OtpSolicitarScreenState();
}

class _OtpSolicitarScreenState extends ConsumerState<OtpSolicitarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _solicitar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.solicitarOtp(_telefonoCtrl.text.trim());
      if (!mounted) return;
      context.push('/login/verificar', extra: _telefonoCtrl.text.trim());
    } catch (e) {
      if (!mounted) return;
      final error = DioClient.mapearError(e);
      if (error.esRateLimit) {
        mostrarError(context, 'Demasiados intentos. Espera un momento antes de volver a pedir el código.');
      } else {
        mostrarError(context, error.errorDe('telefono') ?? error.mensaje);
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AuthScaffold(
      tituloHeader: 'Login',
      titulo: 'FullPinta',
      subtitulo: 'Tu estilo, en buenas manos · Guayaquil',
      debajoDeLaCard: [
        TextButton.icon(
          onPressed: () => context.push('/login/correo'),
          icon: const Icon(Icons.mail_outline, size: 18),
          label: const Text('Prefiero entrar con correo y contraseña'),
        ),
        Row(
          children: [
            Expanded(child: Divider(color: scheme.onSurface.withValues(alpha: 0.08))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('o', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
            ),
            Expanded(child: Divider(color: scheme.onSurface.withValues(alpha: 0.08))),
          ],
        ),
        Center(
          child: TextButton(
            onPressed: () => context.push('/registro/correo'),
            child: const Text('¿Primera vez en FullPinta? Crear cuenta con correo'),
          ),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ingresa tu celular', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Te enviaremos un código de confirmación por WhatsApp al instante.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Número de teléfono',
                hintText: '09X XXX XXXX',
                prefixIcon: Icon(Icons.phone_iphone_outlined),
              ),
              validator: AppValidators.telefono,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.chat_outlined, size: 16, color: scheme.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Priorizamos entrega vía WhatsApp oficial',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Enviar código', onPressed: _solicitar, isLoading: _cargando, icon: Icons.arrow_forward),
            const SizedBox(height: 16),
            TrustRow(items: [
              (Icons.shield_outlined, 'Sin contraseñas'),
              (Icons.bolt, 'Acceso en 1 clic'),
            ]),
          ],
        ),
      ),
    );
  }
}
