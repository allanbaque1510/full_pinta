import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../data/models/catalog_models.dart';
import '../../state/repository_providers.dart';

/// Cómo un local pide que la plataforma agregue un servicio que le falta
/// (§4.5). Sin aprobar/rechazar desde la app: no hay panel de soporte de
/// plataforma todavía (ver `context/plan-implementacion.md`), se revisan a mano.
class SolicitudesCatalogoScreen extends ConsumerStatefulWidget {
  final String localId;

  const SolicitudesCatalogoScreen({super.key, required this.localId});

  @override
  ConsumerState<SolicitudesCatalogoScreen> createState() => _SolicitudesCatalogoScreenState();
}

class _SolicitudesCatalogoScreenState extends ConsumerState<SolicitudesCatalogoScreen> {
  AsyncValue<List<SolicitudCatalogo>> _solicitudes = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _solicitudes = const AsyncValue.loading());
    try {
      final lista = await ref.read(catalogRepositoryProvider).listarSolicitudes(widget.localId);
      if (mounted) setState(() => _solicitudes = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _solicitudes = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _crear() async {
    await showAppFormSheet(
      context,
      title: 'Solicitar servicio nuevo',
      child: _SolicitudForm(
        onGuardar: (vertical, nombre, descripcion) async {
          try {
            await ref.read(catalogRepositoryProvider).crearSolicitud(
                  widget.localId,
                  vertical: vertical,
                  nombrePropuesto: nombre,
                  descripcion: descripcion,
                );
            if (mounted) Navigator.of(context).pop();
            _cargar();
          } catch (e) {
            if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<SolicitudCatalogo>(
      titulo: 'Solicitudes al catálogo',
      items: _solicitudes,
      onRetry: _cargar,
      onCrear: _crear,
      mensajeVacio: '¿Te falta un servicio en el catálogo? Pídelo aquí.',
      iconoVacio: Icons.add_shopping_cart_outlined,
      itemBuilder: (context, s) => CrudTile(
        icono: Icons.add_shopping_cart_outlined,
        titulo: s.nombrePropuesto,
        subtitulo: '${etiquetaVertical(s.vertical)} · ${_etiquetaEstado(s.estado)}',
      ),
    );
  }

  String _etiquetaEstado(String estado) => switch (estado) {
        'pendiente' => 'Pendiente de revisión',
        'aprobada' => 'Aprobada',
        'rechazada' => 'Rechazada',
        _ => estado,
      };
}

class _SolicitudForm extends StatefulWidget {
  final Future<void> Function(String vertical, String nombre, String? descripcion) onGuardar;

  const _SolicitudForm({required this.onGuardar});

  @override
  State<_SolicitudForm> createState() => _SolicitudFormState();
}

class _SolicitudFormState extends State<_SolicitudForm> {
  final _formKey = GlobalKey<FormState>();
  String _vertical = verticalesDisponibles.first;
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _vertical,
            decoration: const InputDecoration(labelText: 'Vertical'),
            items: verticalesDisponibles.map((v) => DropdownMenuItem(value: v, child: Text(etiquetaVertical(v)))).toList(),
            onChanged: (v) => setState(() => _vertical = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre del servicio'),
            validator: (v) => AppValidators.requerido(v, 'El nombre'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descripcionCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
          ),
          const SizedBox(height: 16),
          FormSubmitButton(
            formKey: _formKey,
            label: 'Enviar solicitud',
            onGuardar: () => widget.onGuardar(
              _vertical,
              _nombreCtrl.text.trim(),
              _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
            ),
          ),
        ],
      ),
    );
  }
}
