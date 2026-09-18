import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/repository_providers.dart';
import '../../state/session_controller.dart';

/// Derecho de eliminación (§13.1) — `DELETE /cuenta` anonimiza (no borra
/// físicamente, el historial de citas sigue cuadrando) y no tiene vuelta
/// atrás: sin endpoint para deshacerlo.
class EliminarCuentaScreen extends ConsumerStatefulWidget {
  const EliminarCuentaScreen({super.key});

  @override
  ConsumerState<EliminarCuentaScreen> createState() => _EliminarCuentaScreenState();
}

class _EliminarCuentaScreenState extends ConsumerState<EliminarCuentaScreen> {
  bool _entendido = false;
  bool _eliminando = false;

  Future<void> _eliminar() async {
    final ok = await confirmarDialogo(
      context,
      titulo: 'Esta acción no se puede deshacer',
      mensaje: 'Tu cuenta quedará anonimizada de inmediato y se cerrará tu sesión en todos los dispositivos.',
      textoConfirmar: 'Eliminar mi cuenta',
      destructivo: true,
    );
    if (!ok) return;

    setState(() => _eliminando = true);
    try {
      await ref.read(identityRepositoryProvider).eliminarCuenta();
      await ref.read(sessionControllerProvider.notifier).cerrarSesion();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar mi cuenta')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.peligro),
              const SizedBox(height: 16),
              Text(
                'Al eliminar tu cuenta:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text('• Tu nombre, teléfono, correo y foto quedan irreconocibles.'),
              const Text('• Se cierran todas tus sesiones activas.'),
              const Text('• El historial de tus citas se conserva de forma anónima (lo necesitan los locales para sus estadísticas).'),
              const Text('• No hay forma de deshacer esto ni de recuperar la cuenta.'),
              const SizedBox(height: 24),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _entendido,
                onChanged: (v) => setState(() => _entendido = v ?? false),
                title: const Text('Entiendo que esta acción es permanente'),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Eliminar mi cuenta',
                onPressed: _entendido ? _eliminar : null,
                isLoading: _eliminando,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
