import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/otp_code_input.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/repository_providers.dart';
import '../../state/session_controller.dart';

/// Verificación de propiedad del correo: envía un código al email ya
/// registrado y lo confirma; actualiza el usuario en sesión.
class VerificarEmailScreen extends ConsumerStatefulWidget {
  const VerificarEmailScreen({super.key});

  @override
  ConsumerState<VerificarEmailScreen> createState() => _VerificarEmailScreenState();
}

class _VerificarEmailScreenState extends ConsumerState<VerificarEmailScreen> {
  String _codigo = '';
  bool _codigoEnviado = false;
  bool _cargando = false;

  Future<void> _solicitar() async {
    setState(() => _cargando = true);
    try {
      await ref.read(identityRepositoryProvider).solicitarVerificacionEmail();
      if (!mounted) return;
      setState(() => _codigoEnviado = true);
      mostrarMensaje(context, 'Te enviamos un código a tu correo.');
    } catch (e) {
      if (mounted) {
        final error = DioClient.mapearError(e);
        mostrarError(context, error.errorDe('email') ?? error.mensaje);
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _verificar() async {
    if (_codigo.length != 6) {
      mostrarError(context, 'Ingresa los 6 dígitos del código.');
      return;
    }
    setState(() => _cargando = true);
    try {
      final usuario = await ref.read(identityRepositoryProvider).verificarEmail(_codigo);
      ref.read(sessionControllerProvider.notifier).usuarioActualizado(usuario);
      if (!mounted) return;
      mostrarMensaje(context, 'Correo verificado.');
      context.pop();
    } catch (e) {
      if (mounted) {
        final error = DioClient.mapearError(e);
        mostrarError(context, error.errorDe('codigo') ?? error.mensaje);
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(sessionControllerProvider).usuario;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final email = usuario?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Verificar correo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (email == null)
            Text('Tu cuenta no tiene un correo registrado.', style: textTheme.bodyMedium)
          else if (usuario!.emailVerificado)
            Row(
              children: [
                Icon(Icons.verified, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('$email ya está verificado.', style: textTheme.bodyMedium)),
              ],
            )
          else ...[
            Text(
              'Confirma que $email es tuyo. Te enviaremos un código de 6 dígitos.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (!_codigoEnviado)
              PrimaryButton(label: 'Enviar código', onPressed: _solicitar, isLoading: _cargando, icon: Icons.send)
            else ...[
              Text('Código de verificación', style: textTheme.labelMedium),
              const SizedBox(height: 10),
              OtpCodeInput(onChanged: (v) => setState(() => _codigo = v)),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Verificar', onPressed: _verificar, isLoading: _cargando, icon: Icons.check),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _cargando ? null : _solicitar, child: const Text('Reenviar código')),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
