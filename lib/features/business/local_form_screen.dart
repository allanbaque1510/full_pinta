import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/location.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/directory_models.dart';
import '../../state/repository_providers.dart';

/// `POST /negocios/{id}/locales` — sin mapa embebido (sin API key de
/// Google Maps todavía, ver `core/config/api_config.dart`): lat/lng se
/// completan con la ubicación actual del dispositivo y quedan editables a
/// mano para ajustar la dirección exacta.
class LocalFormScreen extends ConsumerStatefulWidget {
  final String negocioId;

  /// Si viene, el formulario edita ese local (PATCH) en vez de crear uno nuevo.
  final Local? local;

  const LocalFormScreen({super.key, required this.negocioId, this.local});

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
  final _leadTimeCtrl = TextEditingController(text: '60');
  final _horizonteCtrl = TextEditingController(text: '30');
  final _cancelacionCtrl = TextEditingController(text: '2');
  bool _guardando = false;
  bool _ubicando = true;

  @override
  void initState() {
    super.initState();
    final l = widget.local;
    if (l != null) {
      _nombreCtrl.text = l.nombre;
      _direccionCtrl.text = l.direccion;
      _referenciaCtrl.text = l.referencia ?? '';
      _telefonoCtrl.text = l.telefono ?? '';
      _whatsappCtrl.text = l.whatsapp ?? '';
      _latCtrl.text = l.lat.toStringAsFixed(6);
      _lngCtrl.text = l.lng.toStringAsFixed(6);
      _leadTimeCtrl.text = '${l.leadTimeMin}';
      _horizonteCtrl.text = '${l.horizonteDias}';
      _cancelacionCtrl.text = '${l.politicaCancelacionHoras}';
      _ubicando = false;
      return;
    }
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
    _leadTimeCtrl.dispose();
    _horizonteCtrl.dispose();
    _cancelacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final repo = ref.read(directoryRepositoryProvider);
      final nombre = _nombreCtrl.text.trim();
      final direccion = _direccionCtrl.text.trim();
      final referencia = _referenciaCtrl.text.trim();
      final lat = double.parse(_latCtrl.text);
      final lng = double.parse(_lngCtrl.text);
      final telefono = _telefonoCtrl.text.trim();
      final whatsapp = _whatsappCtrl.text.trim();
      final leadTime = int.parse(_leadTimeCtrl.text.trim());
      final horizonte = int.parse(_horizonteCtrl.text.trim());
      final cancelacion = int.parse(_cancelacionCtrl.text.trim());
      final existente = widget.local;
      if (existente != null) {
        final actualizado = await repo.actualizarLocal(
          existente.id,
          nombre: nombre,
          direccion: direccion,
          referencia: referencia,
          lat: lat,
          lng: lng,
          telefono: telefono,
          whatsapp: whatsapp,
          leadTimeMin: leadTime,
          horizonteDias: horizonte,
          politicaCancelacionHoras: cancelacion,
        );
        if (!mounted) return;
        context.pop(actualizado);
        return;
      }
      final local = await repo.crearLocal(
        widget.negocioId,
        nombre: nombre,
        direccion: direccion,
        referencia: referencia,
        lat: lat,
        lng: lng,
        telefono: telefono,
        whatsapp: whatsapp,
        leadTimeMin: leadTime,
        horizonteDias: horizonte,
        politicaCancelacionHoras: cancelacion,
      );
      if (!mounted) return;
      context.pushReplacement('/locales/${local.id}/admin');
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String? _enteroNoNegativo(String? v, String campo) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < 0) return '$campo debe ser un entero mayor o igual a 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.local == null ? 'Nuevo local' : 'Editar local')),
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
                const SizedBox(height: 16),
                Text('Reglas de reserva', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _leadTimeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Anticipación mínima (minutos)',
                    helperText: 'Cuánto antes de la hora hay que reservar.',
                  ),
                  validator: (v) => _enteroNoNegativo(v, 'La anticipación'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _horizonteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Horizonte de agendamiento (días)',
                    helperText: 'Hasta cuántos días a futuro se puede reservar.',
                  ),
                  validator: (v) => _enteroNoNegativo(v, 'El horizonte'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cancelacionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Política de cancelación (horas)',
                    helperText: 'Horas antes en que se puede cancelar sin penalidad.',
                  ),
                  validator: (v) => _enteroNoNegativo(v, 'La política de cancelación'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: widget.local == null ? 'Crear local' : 'Guardar cambios',
                  onPressed: _guardar,
                  isLoading: _guardando,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
