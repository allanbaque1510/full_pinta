import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/location.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/repository_providers.dart';

/// `POST /negocios/{id}/locales` — sin mapa embebido (sin API key de
/// Google Maps todavía, ver `core/config/api_config.dart`): lat/lng se
/// completan con la ubicación actual del dispositivo y quedan editables a
/// mano para ajustar la dirección exacta.
class LocalFormScreen extends ConsumerStatefulWidget {
  final String negocioId;

  const LocalFormScreen({super.key, required this.negocioId});

  @override
  ConsumerState<LocalFormScreen> createState() => _LocalFormScreenState();
}

class _LocalFormScreenState extends ConsumerState<LocalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  bool _guardando = false;
  bool _ubicando = true;

  @override
  void initState() {
    super.initState();
    _autocompletarUbicacion();
  }

  Future<void> _autocompletarUbicacion() async {
    final ubicacion = await AppLocation.obtenerUbicacionActual();
    if (!mounted) return;
    setState(() {
      _latCtrl.text = ubicacion.lat.toStringAsFixed(6);
      _lngCtrl.text = ubicacion.lng.toStringAsFixed(6);
      _ubicando = false;
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _referenciaCtrl.dispose();
    _telefonoCtrl.dispose();
    _whatsappCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final local = await ref.read(directoryRepositoryProvider).crearLocal(
            widget.negocioId,
            nombre: _nombreCtrl.text.trim(),
            direccion: _direccionCtrl.text.trim(),
            referencia: _referenciaCtrl.text.trim(),
            lat: double.parse(_latCtrl.text),
            lng: double.parse(_lngCtrl.text),
            telefono: _telefonoCtrl.text.trim(),
            whatsapp: _whatsappCtrl.text.trim(),
          );
      if (!mounted) return;
      context.pushReplacement('/locales/${local.id}/admin');
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo local')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'El local nace en borrador: no aparece en búsquedas hasta que lo actives.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre (ej. "Sucursal Alborada")'),
                  validator: (v) => AppValidators.requerido(v, 'El nombre'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  validator: (v) => AppValidators.requerido(v, 'La dirección'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _referenciaCtrl,
                  decoration: const InputDecoration(labelText: 'Referencia (opcional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _whatsappCtrl,
                  decoration: const InputDecoration(labelText: 'WhatsApp (opcional)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text('Ubicación', style: Theme.of(context).textTheme.labelLarge),
                    ),
                    if (_ubicando) const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Lat'),
                        validator: (v) => AppValidators.numeroPositivo(v?.replaceFirst('-', ''), 'La latitud'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Lng'),
                        validator: (v) => AppValidators.numeroPositivo(v?.replaceFirst('-', ''), 'La longitud'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Crear local', onPressed: _crear, isLoading: _guardando),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
