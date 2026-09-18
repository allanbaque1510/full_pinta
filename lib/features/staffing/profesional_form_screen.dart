import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

/// Alta de un profesional nuevo junto con su primera asignación (§4.6). Para
/// sumar uno que ya existe a otro local se usa la pantalla de asignaciones.
class ProfesionalFormScreen extends ConsumerStatefulWidget {
  final String localId;

  const ProfesionalFormScreen({super.key, required this.localId});

  @override
  ConsumerState<ProfesionalFormScreen> createState() => _ProfesionalFormScreenState();
}

class _ProfesionalFormScreenState extends ConsumerState<ProfesionalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _comisionCtrl = TextEditingController(text: '50');
  String _rol = rolesStaffing.first;
  String _modalidad = modalidadesAsignacion.first;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _aliasCtrl.dispose();
    _bioCtrl.dispose();
    _comisionCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await ref.read(staffingRepositoryProvider).crearProfesional(
            widget.localId,
            nombre: _nombreCtrl.text.trim(),
            alias: _aliasCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            rol: _rol,
            modalidad: _modalidad,
            comisionPct: double.tryParse(_comisionCtrl.text.replaceAll(',', '.')) ?? 0,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo profesional')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                  validator: (v) => AppValidators.requerido(v, 'El nombre'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _aliasCtrl,
                  decoration: const InputDecoration(labelText: 'Alias (opcional, ej. "Kevin el Fade")'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Bio (opcional)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _rol,
                  decoration: const InputDecoration(labelText: 'Rol en este local'),
                  items: rolesStaffing.map((r) => DropdownMenuItem(value: r, child: Text(etiquetaRolStaffing(r)))).toList(),
                  onChanged: (v) => setState(() => _rol = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _modalidad,
                  decoration: const InputDecoration(labelText: 'Modalidad'),
                  items: modalidadesAsignacion
                      .map((m) => DropdownMenuItem(value: m, child: Text(_etiquetaModalidad(m))))
                      .toList(),
                  onChanged: (v) => setState(() => _modalidad = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _comisionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Comisión (%)'),
                  validator: (v) => AppValidators.numeroPositivo(v, 'La comisión'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Dar de alta', onPressed: _crear, isLoading: _guardando),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _etiquetaModalidad(String m) => switch (m) {
        'empleado' => 'Empleado',
        'renta_silla' => 'Renta de silla',
        'invitado' => 'Invitado',
        _ => m,
      };
}
