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
import '../../data/models/catalog_models.dart';
import '../../state/repository_providers.dart';

/// Productos (pomada, cera, shampoo) — llevan comisión propia, distinta a
/// la de un servicio (§4.5), para que la liquidación salga correcta.
class LocalProductosScreen extends ConsumerStatefulWidget {
  final String localId;

  const LocalProductosScreen({super.key, required this.localId});

  @override
  ConsumerState<LocalProductosScreen> createState() => _LocalProductosScreenState();
}

class _LocalProductosScreenState extends ConsumerState<LocalProductosScreen> {
  AsyncValue<List<Producto>> _productos = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _productos = const AsyncValue.loading());
    try {
      final lista = await ref.read(catalogRepositoryProvider).listarProductos(widget.localId);
      if (mounted) setState(() => _productos = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _productos = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  Future<void> _crear() async {
    await showAppFormSheet(
      context,
      title: 'Nuevo producto',
      child: _ProductoForm(
        onGuardar: (nombre, precio, comision) async {
          try {
            await ref.read(catalogRepositoryProvider).crearProducto(
                  widget.localId,
                  nombre: nombre,
                  precio: precio,
                  comisionPct: comision,
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

  Future<void> _eliminar(Producto p) async {
    final ok = await confirmarDialogo(context, titulo: 'Quitar producto', mensaje: 'Se desactiva el producto.', destructivo: true);
    if (!ok) return;
    try {
      await ref.read(catalogRepositoryProvider).eliminarProducto(p.id);
      _cargar();
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<Producto>(
      titulo: 'Productos',
      items: _productos,
      onRetry: _cargar,
      onCrear: _crear,
      mensajeVacio: 'Todavía no registras productos.',
      iconoVacio: Icons.shopping_bag_outlined,
      etiquetaContador: 'productos registrados',
      itemBuilder: (context, p) => CrudTile(
        icono: Icons.shopping_bag_outlined,
        titulo: '${p.nombre}${p.activo ? '' : ' (inactivo)'}',
        subtitulo: '${AppFormatters.dinero(p.precio)} · comisión ${p.comisionPct}%',
        onEliminar: p.activo ? () => _eliminar(p) : null,
      ),
    );
  }
}

class _ProductoForm extends StatefulWidget {
  final Future<void> Function(String nombre, double precio, double comisionPct) onGuardar;

  const _ProductoForm({required this.onGuardar});

  @override
  State<_ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends State<_ProductoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _comisionCtrl = TextEditingController(text: '15');
  bool _comisionable = false;

  @override
  void initState() {
    super.initState();
    _precioCtrl.addListener(_refrescar);
    _comisionCtrl.addListener(_refrescar);
  }

  @override
  void dispose() {
    _precioCtrl.removeListener(_refrescar);
    _comisionCtrl.removeListener(_refrescar);
    _nombreCtrl.dispose();
    _precioCtrl.dispose();
    _comisionCtrl.dispose();
    super.dispose();
  }

  void _refrescar() => setState(() {});

  double get _montoEstimado {
    final precio = double.tryParse(_precioCtrl.text.replaceAll(',', '.')) ?? 0;
    final pct = double.tryParse(_comisionCtrl.text.replaceAll(',', '.')) ?? 0;
    return precio * pct / 100;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (v) => AppValidators.requerido(v, 'El nombre'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _precioCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Precio'),
            validator: (v) => AppValidators.numeroPositivo(v, 'El precio'),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Genera comisión al profesional'),
              subtitle: const Text('Calcula el porcentaje pactado por la venta del producto.'),
              value: _comisionable,
              onChanged: (v) => setState(() {
                _comisionable = v;
                if (!v) _comisionCtrl.text = '0';
                if (v && _comisionCtrl.text == '0') _comisionCtrl.text = '15';
              }),
            ),
          ),
          if (_comisionable) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _comisionCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Porcentaje de comisión (%)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monto estimado', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                      Text(AppFormatters.dineroNum(_montoEstimado), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.tertiary)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FormSubmitButton(
            formKey: _formKey,
            onGuardar: () => widget.onGuardar(
              _nombreCtrl.text.trim(),
              double.parse(_precioCtrl.text.replaceAll(',', '.')),
              double.tryParse(_comisionCtrl.text.replaceAll(',', '.')) ?? 0,
            ),
          ),
        ],
      ),
    );
  }
}
