import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/icon_avatar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import '../../state/session_controller.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _cargando = false;
  bool _verPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final sesion = await repo.loginPorCorreo(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await ref.read(sessionControllerProvider.notifier).sesionIniciada(sesion.usuario);
    } catch (e) {
      if (!mounted) return;
      final error = DioClient.mapearError(e);
      if (error.esRateLimit) {
        mostrarError(context, 'Demasiados intentos. Espera unos minutos.');
      } else {
        mostrarError(context, error.errorDe('password') ?? error.mensaje);
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
      etiquetaSuperior: 'Tu estilo a tiempo',
      titulo: 'Entrar con correo',
      subtitulo: 'Accede con tu cuenta de correo y contraseña para gestionar tus citas.',
      debajoDeLaCard: [
        SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const IconAvatar(icono: Icons.smartphone_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Prefieres entrar sin clave?', style: Theme.of(context).textTheme.labelMedium),
                    Text(
                      'Te enviamos un código por WhatsApp',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: () => context.pop(), child: const Text('SMS')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => context.push('/registro/correo'),
            child: const Text('¿No tienes cuenta? Crear cuenta'),
          ),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline)),
              validator: AppValidators.email,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: !_verPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _verPassword = !_verPassword),
                ),
              ),
              validator: AppValidators.password,
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Entrar', onPressed: _entrar, isLoading: _cargando, icon: Icons.arrow_forward),
            const SizedBox(height: 12),
            TrustRow(items: const [(Icons.verified_user_outlined, 'Conexión cifrada de alta seguridad')]),
          ],
        ),
      ),
    );
  }
}
