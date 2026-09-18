import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../core/widgets/surface_card.dart';
import '../../core/widgets/tag_pill.dart';
import '../../data/models/catalog_models.dart';
import '../../state/repository_providers.dart';

/// El catálogo de servicios es maestro y cerrado (§4.5, §2 "nunca texto
/// libre"): acá solo se elige un `CatalogoServicio` existente y se fija
/// precio/duración propios del local.
class LocalServiciosScreen extends ConsumerStatefulWidget {
  final String localId;

  const LocalServiciosScreen({super.key, required this.localId});

  @override
  ConsumerState<LocalServiciosScreen> createState() => _LocalServiciosScreenState();
}

class _LocalServiciosScreenState extends ConsumerState<LocalServiciosScreen> {
  AsyncValue<List<ServicioLocal>> _servicios = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _servicios = const AsyncValue.loading());
    try {
      final lista = await ref.read(catalogRepositoryProvider).listarServiciosLocal(widget.localId);
      if (mounted) setState(() => _servicios = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _servicios = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _crear() async {
    final catalogo = await ref.read(catalogRepositoryProvider).servicios();
    if (!mounted) return;
    await showAppFormSheet(
      context,
      title: 'Nuevo servicio',
      child: _ServicioForm(
        catalogo: catalogo,
        onGuardar: (catalogoId, precio, duracion, buffer, comisionable) async {
          try {
            await ref.read(catalogRepositoryProvider).crearServicioLocal(
                  widget.localId,
                  catalogoServicioId: catalogoId,
                  precio: precio,
                  duracionMin: duracion,
                  bufferMin: buffer,
                  comisionable: comisionable,
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

  Future<void> _eliminar(ServicioLocal s) async {
    final ok = await confirmarDialogo(
      context,
      titulo: 'Quitar servicio',
      mensaje: 'Se desactiva el servicio (no se borra: las citas ya agendadas conservan su precio).',
      destructivo: true,
    );
    if (!ok) return;
    try {
      await ref.read(catalogRepositoryProvider).eliminarServicioLocal(s.id);
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<ServicioLocal>(
      titulo: 'Servicios y precios',
      items: _servicios,
      onRetry: _cargar,
      onCrear: _crear,
      mensajeVacio: 'Todavía no das de alta ningún servicio.',
      iconoVacio: Icons.design_services_outlined,
      etiquetaContador: 'servicios configurados',
      itemBuilder: (context, s) => CrudTile(
        icono: Icons.design_services_outlined,
        titulo: '${s.nombre}${s.activo ? '' : ' (inactivo)'}',
        subtitulo: '${AppFormatters.dinero(s.precio)} · ${AppFormatters.duracion(s.duracionMin)}',
        etiquetas: [
          TagPill(
            texto: s.comisionable ? 'Genera comisión' : 'Sin comisión',
            color: s.comisionable ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
        onEliminar: s.activo ? () => _eliminar(s) : null,
      ),
    );
  }
}

class _ServicioForm extends StatefulWidget {
  final List<CatalogoServicio> catalogo;
  final Future<void> Function(String catalogoId, double precio, int duracion, int buffer, bool comisionable) onGuardar;

  const _ServicioForm({required this.catalogo, required this.onGuardar});

  @override
  State<_ServicioForm> createState() => _ServicioFormState();
}

class _ServicioFormState extends State<_ServicioForm> {
  final _formKey = GlobalKey<FormState>();
  String? _catalogoId;
  final _precioCtrl = TextEditingController();
  final _duracionCtrl = TextEditingController();
  final _bufferCtrl = TextEditingController(text: '0');
  bool _comisionable = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _catalogoId,
            decoration: const InputDecoration(labelText: 'Servicio del catálogo'),
            items: widget.catalogo
                .map((c) => DropdownMenuItem(value: c.id, child: Text('${etiquetaVertical(c.vertical)} · ${c.nombre}')))
                .toList(),
            onChanged: (v) {
              setState(() {
                _catalogoId = v;
                final elegido = widget.catalogo.firstWhere((c) => c.id == v);
                _duracionCtrl.text = elegido.duracionBaseMin.toString();
              });
            },
            validator: (v) => v == null ? 'Elige un servicio' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _precioCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Precio'),
            validator: (v) => AppValidators.numeroPositivo(v, 'El precio'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _duracionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duración (min)'),
                  validator: (v) => AppValidators.enteroPositivo(v, 'La duración'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _bufferCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Buffer (min)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Genera comisión al profesional'),
              subtitle: const Text('El porcentaje se calcula desde la configuración del negocio.'),
              value: _comisionable,
              onChanged: (v) => setState(() => _comisionable = v),
            ),
          ),
          const SizedBox(height: 16),
          FormSubmitButton(
            formKey: _formKey,
            onGuardar: () => widget.onGuardar(
              _catalogoId!,
              double.parse(_precioCtrl.text.replaceAll(',', '.')),
              int.parse(_duracionCtrl.text),
              int.tryParse(_bufferCtrl.text) ?? 0,
              _comisionable,
            ),
          ),
        ],
      ),
    );
  }
}
