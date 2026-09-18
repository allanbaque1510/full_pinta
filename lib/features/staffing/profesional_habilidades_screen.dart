import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../data/models/catalog_models.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

/// La tabla que rompe el agendamiento si falta (§4.6): una cita solo puede
/// asignarse a un profesional con habilidad para ese servicio.
class ProfesionalHabilidadesScreen extends ConsumerStatefulWidget {
  final String profesionalId;
  final String localId;

  const ProfesionalHabilidadesScreen({super.key, required this.profesionalId, required this.localId});

  @override
  ConsumerState<ProfesionalHabilidadesScreen> createState() => _ProfesionalHabilidadesScreenState();
}

class _ProfesionalHabilidadesScreenState extends ConsumerState<ProfesionalHabilidadesScreen> {
  AsyncValue<List<Habilidad>> _habilidades = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _habilidades = const AsyncValue.loading());
    try {
      final lista = await ref.read(staffingRepositoryProvider).listarHabilidades(widget.profesionalId);
      if (mounted) setState(() => _habilidades = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _habilidades = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _crear() async {
    final servicios = await ref.read(catalogRepositoryProvider).listarServiciosLocal(widget.localId);
    if (!mounted) return;
    final activos = servicios.where((s) => s.activo).toList();
    if (activos.isEmpty) {
      mostrarError(context, 'Este local todavía no tiene servicios activos para asignar.');
      return;
    }
    await showAppFormSheet(
      context,
      title: 'Nueva habilidad',
      child: _HabilidadForm(
        servicios: activos,
        onGuardar: (servicioId) async {
          try {
            await ref.read(staffingRepositoryProvider).crearHabilidad(widget.profesionalId, servicioLocalId: servicioId);
            if (mounted) Navigator.of(context).pop();
            _cargar();
          } catch (e) {
            if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
          }
        },
      ),
    );
  }

  Future<void> _eliminar(Habilidad h) async {
    final ok = await confirmarDialogo(context, titulo: 'Quitar habilidad', mensaje: 'Ya no podrá atender este servicio.', destructivo: true);
    if (!ok) return;
    try {
      await ref.read(staffingRepositoryProvider).eliminarHabilidad(widget.profesionalId, h.id);
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<Habilidad>(
      titulo: 'Habilidades',
      items: _habilidades,
      onRetry: _cargar,
      onCrear: _crear,
      mensajeVacio: 'Todavía no marcas qué servicios atiende.',
      iconoVacio: Icons.design_services_outlined,
      itemBuilder: (context, h) => CrudTile(
        icono: Icons.check_circle_outline,
        titulo: h.servicioNombre,
        onEliminar: () => _eliminar(h),
      ),
    );
  }
}

class _HabilidadForm extends StatefulWidget {
  final List<ServicioLocal> servicios;
  final Future<void> Function(String servicioLocalId) onGuardar;

  const _HabilidadForm({required this.servicios, required this.onGuardar});

  @override
  State<_HabilidadForm> createState() => _HabilidadFormState();
}

class _HabilidadFormState extends State<_HabilidadForm> {
  String? _servicioId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _servicioId,
          decoration: const InputDecoration(labelText: 'Servicio'),
          items: widget.servicios.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombre))).toList(),
          onChanged: (v) => setState(() => _servicioId = v),
        ),
        const SizedBox(height: 16),
        FormSubmitButton(
          enabled: _servicioId != null,
          onGuardar: () => widget.onGuardar(_servicioId!),
        ),
      ],
    );
  }
}
