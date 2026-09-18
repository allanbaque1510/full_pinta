import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/otp_code_input.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/session_controller.dart';

class OtpVerificarScreen extends ConsumerStatefulWidget {
  final String telefono;

  const OtpVerificarScreen({super.key, required this.telefono});

  @override
  ConsumerState<OtpVerificarScreen> createState() => _OtpVerificarScreenState();
}

class _OtpVerificarScreenState extends ConsumerState<OtpVerificarScreen> {
  final _otpKey = GlobalKey<OtpCodeInputState>();
  final _nombreCtrl = TextEditingController();
  String _codigo = '';
  bool _cargando = false;
  bool _reenviando = false;
  Timer? _timer;
  int _segundosRestantes = 45;

  @override
  void initState() {
    super.initState();
    _iniciarCuentaRegresiva();
  }

  void _iniciarCuentaRegresiva() {
    _segundosRestantes = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundosRestantes <= 0) {
        t.cancel();
        return;
      }
      setState(() => _segundosRestantes--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    if (_codigo.length != 6) {
      mostrarError(context, 'Ingresa los 6 dígitos del código.');
      return;
    }
    setState(() => _cargando = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final sesion = await repo.verificarOtp(
        telefono: widget.telefono,
        codigo: _codigo,
        nombre: _nombreCtrl.text.trim().isEmpty ? null : _nombreCtrl.text.trim(),
      );
      await ref.read(sessionControllerProvider.notifier).sesionIniciada(sesion.usuario);
    } catch (e) {
      if (!mounted) return;
      final error = DioClient.mapearError(e);
      if (error.codigo == 'otp_incorrecto') {
        mostrarError(context, 'Código incorrecto. Te quedan intentos limitados.');
      } else if (error.errorDe('nombre') != null) {
        mostrarError(context, 'Es tu primera vez: cuéntanos tu nombre para crear tu cuenta.');
      } else {
        mostrarError(context, error.errorDe('codigo') ?? error.mensaje);
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);
    try {
      await ref.read(authRepositoryProvider).solicitarOtp(widget.telefono);
      if (mounted) {
        mostrarMensaje(context, 'Te enviamos un código nuevo.');
        _otpKey.currentState?.limpiar();
        _iniciarCuentaRegresiva();
      }
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AuthScaffold(
      tituloHeader: 'Verificación',
      titulo: 'Verifica tu número',
      subtitulo: 'Ingresa el código rápido para desbloquear tu cita de inmediato',
      debajoDeLaCard: [
        Center(
          child: _segundosRestantes > 0
              ? Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    children: [
                      const TextSpan(text: 'Reenviar código en '),
                      TextSpan(
                        text: '00:${_segundosRestantes.toString().padLeft(2, '0')}',
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : TextButton.icon(
                  onPressed: _reenviando ? null : _reenviar,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(_reenviando ? 'Enviando...' : 'Reenviar código'),
                ),
        ),
        const SizedBox(height: 8),
        TrustRow(items: const [(Icons.shield_outlined, 'Cifrado de extremo a extremo')]),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user, size: 15, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(widget.telefono, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Código de seguridad (6 dígitos)', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          OtpCodeInput(key: _otpKey, onChanged: (v) => setState(() => _codigo = v)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text('Tu nombre completo', style: Theme.of(context).textTheme.labelMedium)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Solo cuenta nueva', style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(hintText: 'Ej. Carlos Mendoza', prefixIcon: Icon(Icons.badge_outlined)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Icons.flash_on, size: 18, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reserva garantizada en 60s', style: Theme.of(context).textTheme.labelMedium),
                      Text(
                        'Sincroniza tus barberías y salones favoritos',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Confirmar y continuar',
            onPressed: _verificar,
            isLoading: _cargando,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }
}
