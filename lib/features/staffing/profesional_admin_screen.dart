import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../core/widgets/menu_access_tile.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

/// Hub de administración de un profesional dentro de un local concreto.
/// `Profesional` no pertenece a un solo local (§4.6, puede trabajar en
/// varios) — por eso todo lo que es "en este local" (turnos, asignación)
/// necesita saber desde qué local se entró, y lo que es propio de la
/// persona (habilidades, fotos, turno-fechas, excepciones) no.
class ProfesionalAdminScreen extends ConsumerStatefulWidget {
  final String profesionalId;
  final String localId;

  const ProfesionalAdminScreen({super.key, required this.profesionalId, required this.localId});

  @override
  ConsumerState<ProfesionalAdminScreen> createState() => _ProfesionalAdminScreenState();
}

class _ProfesionalAdminScreenState extends ConsumerState<ProfesionalAdminScreen> {
  Profesional? _profesional;
  Asignacion? _asignacionEnEsteLocal;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final repo = ref.read(staffingRepositoryProvider);
      final profesional = await repo.obtenerProfesional(widget.profesionalId);
      final asignaciones = await repo.listarAsignaciones(widget.localId);
      final vigentes = asignaciones.where((a) => a.profesionalId == widget.profesionalId && a.vigente).toList();
      if (!mounted) return;
      setState(() {
        _profesional = profesional;
        _asignacionEnEsteLocal = vigentes.isEmpty ? null : vigentes.first;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  bool _terminandoAsignacion = false;

  Future<void> _vincularCuenta() async {
    await showAppFormSheet(
      context,
      title: 'Vincular cuenta',
      child: _VincularCuentaForm(
        onGuardar: (telefono) async {
          try {
            final actualizado =
                await ref.read(staffingRepositoryProvider).vincularCuenta(widget.profesionalId, telefono: telefono);
            if (!mounted) return;
            Navigator.of(context).pop();
            setState(() => _profesional = actualizado);
            mostrarMensaje(context, 'Cuenta vinculada: ya puede iniciar sesión y ver su agenda.');
          } catch (e) {
            if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
          }
        },
      ),
    );
  }

  Future<void> _terminarAsignacion() async {
    if (_asignacionEnEsteLocal == null) return;
    final ok = await confirmarDialogo(
      context,
      titulo: 'Terminar vínculo',
      mensaje: '¿Terminar el vínculo laboral de este profesional con este local?',
      destructivo: true,
    );
    if (!ok) return;
    setState(() => _terminandoAsignacion = true);
    try {
      await ref.read(staffingRepositoryProvider).terminarAsignacion(_asignacionEnEsteLocal!.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _terminandoAsignacion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _profesional == null) {
      return Scaffold(appBar: AppBar(), body: ErrorState(mensaje: _error ?? 'No se pudo cargar.', onRetry: _cargar));
    }

    final p = _profesional!;
    return Scaffold(
      appBar: AppBar(title: Text(p.alias ?? p.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.bio != null && p.bio!.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(p.bio!)),
          if (_asignacionEnEsteLocal != null)
            MenuAccessTile(
              icono: Icons.schedule_outlined,
              titulo: 'Turnos en este local',
              onTap: () => context.push('/asignaciones/${_asignacionEnEsteLocal!.id}/turnos'),
            ),
          MenuAccessTile(
            icono: Icons.manage_accounts_outlined,
            titulo: p.tieneCuentaPropia ? 'Cambiar cuenta vinculada' : 'Vincular cuenta de acceso',
            subtitulo: p.tieneCuentaPropia
                ? 'Ya tiene cuenta propia: inicia sesión y ve su agenda'
                : 'Sin cuenta: el local gestiona su agenda',
            onTap: _vincularCuenta,
          ),
          MenuAccessTile(
            icono: Icons.event_repeat_outlined,
            titulo: 'Cambios de turno por fecha',
            onTap: () => context.push('/profesionales/${p.id}/turno-fechas', extra: widget.localId),
          ),
          MenuAccessTile(
            icono: Icons.design_services_outlined,
            titulo: 'Habilidades (qué atiende)',
            onTap: () => context.push('/profesionales/${p.id}/habilidades', extra: widget.localId),
          ),
          MenuAccessTile(
            icono: Icons.photo_library_outlined,
            titulo: 'Fotos de trabajos',
            onTap: () => context.push('/profesionales/${p.id}/fotos'),
          ),
          MenuAccessTile(
            icono: Icons.event_busy_outlined,
            titulo: 'Ausencias y bloqueos',
            onTap: () => context.push('/profesionales/${p.id}/excepciones'),
          ),
          if (_asignacionEnEsteLocal != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _terminandoAsignacion ? null : _terminarAsignacion,
              icon: _terminandoAsignacion
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link_off),
              label: const Text('Terminar vínculo con este local'),
            ),
          ],
        ],
      ),
    );
  }
}

class _VincularCuentaForm extends StatefulWidget {
  final Future<void> Function(String telefono) onGuardar;

  const _VincularCuentaForm({required this.onGuardar});

  @override
  State<_VincularCuentaForm> createState() => _VincularCuentaFormState();
}

class _VincularCuentaFormState extends State<_VincularCuentaForm> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoCtrl = TextEditingController();

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'La persona debe estar registrada en la app. Se vincula por el teléfono de su cuenta.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Teléfono de la cuenta'),
            validator: (v) => AppValidators.requerido(v, 'El teléfono'),
          ),
          const SizedBox(height: 16),
          FormSubmitButton(
            formKey: _formKey,
            onGuardar: () => widget.onGuardar(_telefonoCtrl.text.trim()),
          ),
        ],
      ),
    );
  }
}
