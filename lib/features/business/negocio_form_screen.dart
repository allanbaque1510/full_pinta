import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/repository_providers.dart';
import '../../state/session_controller.dart';

/// `POST /negocios` — crea el negocio y convierte a quien lo crea en su
/// propietario (§4.4), en la misma transacción del backend.
class NegocioFormScreen extends ConsumerStatefulWidget {
  const NegocioFormScreen({super.key});

  @override
  ConsumerState<NegocioFormScreen> createState() => _NegocioFormScreenState();
}

class _NegocioFormScreenState extends ConsumerState<NegocioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _rucCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rucCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final negocio = await ref.read(directoryRepositoryProvider).crearNegocio(
            nombreMarca: _nombreCtrl.text.trim(),
            ruc: _rucCtrl.text.trim().isEmpty ? null : _rucCtrl.text.trim(),
          );
      await ref.read(sessionControllerProvider.notifier).refrescarContextoAcceso();
      if (!mounted) return;
      context.pushReplacement('/negocios/${negocio.id}');
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear negocio')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'El negocio es tu marca (dueño, RUC, suscripción). Cada sucursal física se agrega después como "local".',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre de la marca'),
                  validator: (v) => AppValidators.requerido(v, 'El nombre'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rucCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'RUC (opcional)'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Crear negocio', onPressed: _crear, isLoading: _guardando),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
