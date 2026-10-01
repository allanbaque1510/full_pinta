import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/otp_code_input.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/session_controller.dart';

/// Recuperar contraseña en dos pasos: elegir canal (WhatsApp o correo) y
/// pedir código; luego código + contraseña nueva. Al restablecer, la API
/// devuelve sesión nueva y el router reacciona al SessionController.
class OlvideContrasenaScreen extends ConsumerStatefulWidget {
  const OlvideContrasenaScreen({super.key});

  @override
  ConsumerState<OlvideContrasenaScreen> createState() => _OlvideContrasenaScreenState();
}

class _OlvideContrasenaScreenState extends ConsumerState<OlvideContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _otpKey = GlobalKey<OtpCodeInputState>();
  String _canal = 'whatsapp';
  String _codigo = '';
  bool _codigoEnviado = false;
  bool _cargando = false;
  bool _verPassword = false;
  int _expiraEn = 5;

  bool get _esWhatsapp => _canal == 'whatsapp';

  @override
  void dispose() {
    _destinoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final destino = _destinoCtrl.text.trim();
      final minutos = await ref.read(authRepositoryProvider).olvideContrasena(
            canal: _canal,
            telefono: _esWhatsapp ? destino : null,
            email: _esWhatsapp ? null : destino,
          );
      if (!mounted) return;
      setState(() {
        _codigoEnviado = true;
        _expiraEn = minutos;
      });
      mostrarMensaje(context, 'Si los datos son válidos, te enviamos un código.');
    } catch (e) {
      if (!mounted) return;
      final error = DioClient.mapearError(e);
      mostrarError(context, error.esRateLimit ? 'Demasiadas solicitudes. Espera unos minutos.' : error.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _restablecer() async {
    if (_codigo.length != 6) {
      mostrarError(context, 'Ingresa los 6 dígitos del código.');
      return;
    }
    if (AppValidators.password(_passwordCtrl.text) != null) {
      mostrarError(context, AppValidators.password(_passwordCtrl.text)!);
      return;
    }
    setState(() => _cargando = true);
    try {
      final destino = _destinoCtrl.text.trim();
      final sesion = await ref.read(authRepositoryProvider).restablecerContrasena(
            canal: _canal,
            telefono: _esWhatsapp ? destino : null,
            email: _esWhatsapp ? null : destino,
            codigo: _codigo,
            password: _passwordCtrl.text,
          );
      await ref.read(sessionControllerProvider.notifier).sesionIniciada(sesion.usuario);
    } catch (e) {
      if (!mounted) return;
      final error = DioClient.mapearError(e);
      mostrarError(context, error.errorDe('codigo') ?? error.errorDe('password') ?? error.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _cambiarDestino() {
    setState(() {
      _codigoEnviado = false;
      _codigo = '';
      _passwordCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AuthScaffold(
      tituloHeader: 'Recuperar acceso',
      titulo: 'Recupera tu contraseña',
      subtitulo: 'Elige dónde quieres recibir un código de 6 dígitos.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'whatsapp', label: Text('WhatsApp'), icon: Icon(Icons.chat_outlined)),
                ButtonSegment(value: 'email', label: Text('Correo'), icon: Icon(Icons.mail_outline)),
              ],
              selected: {_canal},
              onSelectionChanged: _codigoEnviado
                  ? null
                  : (s) => setState(() {
                        _canal = s.first;
                        _destinoCtrl.clear();
                      }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinoCtrl,
              enabled: !_codigoEnviado,
              keyboardType: _esWhatsapp ? TextInputType.phone : TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: _esWhatsapp ? 'Celular (09XXXXXXXX)' : 'Correo electrónico',
                prefixIcon: Icon(_esWhatsapp ? Icons.smartphone_outlined : Icons.mail_outline),
              ),
              validator: _esWhatsapp ? AppValidators.telefono : AppValidators.email,
            ),
            const SizedBox(height: 16),
            if (!_codigoEnviado)
              PrimaryButton(label: 'Enviar código', onPressed: _enviarCodigo, isLoading: _cargando, icon: Icons.send)
            else ...[
              Text('Código de seguridad (6 dígitos)', style: textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                'Vence en $_expiraEn minutos.',
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              OtpCodeInput(key: _otpKey, onChanged: (v) => setState(() => _codigo = v)),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: !_verPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña nueva (mínimo 8 caracteres)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _verPassword = !_verPassword),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Restablecer y entrar',
                onPressed: _restablecer,
                isLoading: _cargando,
                icon: Icons.check,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: _cargando ? null : _cambiarDestino, child: const Text('Cambiar destino')),
                  TextButton(onPressed: _cargando ? null : _enviarCodigo, child: const Text('Reenviar código')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
