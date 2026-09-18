import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/estado_cita_pill.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/catalog_models.dart';
import '../../data/models/scheduling_models.dart';
import '../../state/repository_providers.dart';

/// Vista de staff de una cita (§6): a diferencia de la del cliente, acá se
/// puede cambiar de estado y ver el teléfono (visible desde `confirmada`,
/// §3.3 — el campo ya viene `null` del backend si no aplica).
class CitaStaffDetalleScreen extends ConsumerStatefulWidget {
  final String citaId;

  const CitaStaffDetalleScreen({super.key, required this.citaId});

  @override
  ConsumerState<CitaStaffDetalleScreen> createState() => _CitaStaffDetalleScreenState();
}

class _CitaStaffDetalleScreenState extends ConsumerState<CitaStaffDetalleScreen> {
  Cita? _cita;
  bool _cargando = true;
  String? _error;
  bool _procesando = false;

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
      final cita = await ref.read(schedulingRepositoryProvider).obtenerCita(widget.citaId);
      if (mounted) setState(() => _cita = cita);
    } catch (e) {
      if (mounted) setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _ejecutar(Future<Cita> Function() accion) async {
    setState(() => _procesando = true);
    try {
      final actualizada = await accion();
      if (mounted) setState(() => _cita = actualizada);
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _completar() async {
    final propinaCtrl = TextEditingController();
    final propina = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar cita'),
        content: TextField(
          controller: propinaCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Propina (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(double.tryParse(propinaCtrl.text.replaceAll(',', '.')) ?? 0),
            child: const Text('Completar'),
          ),
        ],
      ),
    );
    if (propina == null) return;
    await _ejecutar(() => ref.read(schedulingRepositoryProvider).completar(widget.citaId, propina: propina));
  }

  Future<void> _agregarProducto() async {
    final productos = await ref.read(catalogRepositoryProvider).listarProductos(_cita!.localId);
    final activos = productos.where((p) => p.activo).toList();
    if (!mounted) return;
    if (activos.isEmpty) {
      mostrarError(context, 'Este local no tiene productos activos.');
      return;
    }
    final elegido = await showDialog<Producto>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Agregar producto'),
        children: activos
            .map((p) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(p),
                  child: Text('${p.nombre} · ${AppFormatters.dinero(p.precio)}'),
                ))
            .toList(),
      ),
    );
    if (elegido == null) return;
    await _ejecutar(() => ref.read(schedulingRepositoryProvider).agregarProducto(widget.citaId, productoId: elegido.id));
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _cita == null) {
      return Scaffold(appBar: AppBar(), body: ErrorState(mensaje: _error ?? 'No se pudo cargar.', onRetry: _cargar));
    }

    final cita = _cita!;
    return Scaffold(
      appBar: AppBar(title: Text('Cita ${cita.codigo}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: Text(AppFormatters.fechaHoraLegible(cita.inicio), style: Theme.of(context).textTheme.titleMedium)),
              EstadoCitaPill(estado: cita.estado),
            ],
          ),
          if (cita.clienteTelefono != null) Text('Cliente: ${cita.clienteTelefono}'),
          if (cita.notaCliente != null && cita.notaCliente!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Nota: ${cita.notaCliente}'),
          ],
          const Divider(height: 32),
          Text('Total: ${AppFormatters.dinero(cita.precioTotal)}', style: Theme.of(context).textTheme.titleSmall),
          if (double.tryParse(cita.propina) != null && double.parse(cita.propina) > 0)
            Text('Propina: ${AppFormatters.dinero(cita.propina)}'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (cita.estado == 'reservada')
                PrimaryButton(
                  label: 'Confirmar',
                  isLoading: _procesando,
                  onPressed: () => _ejecutar(() => ref.read(schedulingRepositoryProvider).confirmar(cita.id)),
                ),
              if (cita.estado == 'confirmada')
                PrimaryButton(
                  label: 'El cliente llegó',
                  isLoading: _procesando,
                  onPressed: () => _ejecutar(() => ref.read(schedulingRepositoryProvider).iniciar(cita.id)),
                ),
              if (cita.estado == 'en_curso')
                PrimaryButton(label: 'Completar', isLoading: _procesando, onPressed: _completar),
              if (cita.estado == 'en_curso')
                OutlinedButton(
                  onPressed: _procesando ? null : _agregarProducto,
                  child: const Text('Agregar producto'),
                ),
              if (cita.estado == 'confirmada' || cita.estado == 'en_curso')
                OutlinedButton(
                  onPressed: _procesando ? null : () => _ejecutar(() => ref.read(schedulingRepositoryProvider).noShow(cita.id)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.peligro),
                  child: const Text('No se presentó'),
                ),
              if (!cita.esTerminal)
                OutlinedButton(
                  onPressed: _procesando ? null : () => _ejecutar(() => ref.read(schedulingRepositoryProvider).cancelar(cita.id)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.peligro),
                  child: const Text('Cancelar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
