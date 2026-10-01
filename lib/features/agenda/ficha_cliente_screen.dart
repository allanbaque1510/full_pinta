import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/models/scheduling_models.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

/// Ficha del cliente en un local (§4.7): nota y profesional preferido
/// editables, más historial de visitas y confiabilidad.
///
/// La confiabilidad (no-shows, cancelaciones tardías, confirmación obligatoria)
/// es de uso interno del staff — esta pantalla solo se abre desde rutas de
/// staff y nunca debe exponerse al propio cliente.
class FichaClienteScreen extends ConsumerStatefulWidget {
  final String localId;
  final String usuarioId;
  final String? clienteNombre;

  const FichaClienteScreen({super.key, required this.localId, required this.usuarioId, this.clienteNombre});

  @override
  ConsumerState<FichaClienteScreen> createState() => _FichaClienteScreenState();
}

class _FichaClienteScreenState extends ConsumerState<FichaClienteScreen> {
  final _notaCtrl = TextEditingController();
  FichaCliente? _ficha;
  List<Profesional> _profesionales = [];
  String? _preferidoId;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final ficha = await ref.read(schedulingRepositoryProvider).fichaCliente(widget.localId, widget.usuarioId);
      List<Profesional> profesionales = [];
      try {
        profesionales = await ref.read(staffingRepositoryProvider).listarProfesionales(widget.localId);
      } catch (_) {
        // Solo alimenta el selector de preferido; la ficha sirve igual sin él.
      }
      if (!mounted) return;
      setState(() {
        _ficha = ficha;
        _profesionales = profesionales;
        _aplicar(ficha);
      });
    } catch (e) {
      if (mounted) setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _aplicar(FichaCliente ficha) {
    _notaCtrl.text = ficha.nota ?? '';
    final existe = _profesionales.any((p) => p.id == ficha.profesionalPreferidoId);
    _preferidoId = existe ? ficha.profesionalPreferidoId : null;
  }

  Future<void> _guardar() async {
    final ficha = _ficha;
    if (ficha == null) return;
    setState(() => _guardando = true);
    try {
      final actualizada = await ref.read(schedulingRepositoryProvider).actualizarFichaCliente(
            widget.localId,
            widget.usuarioId,
            nota: _notaCtrl.text.trim(),
            profesionalPreferidoId: _preferidoId,
            quitarPreferido: _preferidoId == null && ficha.profesionalPreferidoId != null,
          );
      if (!mounted) return;
      setState(() {
        _ficha = actualizada;
        _aplicar(actualizada);
      });
      mostrarMensaje(context, 'Ficha actualizada.');
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.clienteNombre ?? 'Ficha del cliente';
    if (_cargando) return Scaffold(appBar: AppBar(title: Text(titulo)), body: const Center(child: CircularProgressIndicator()));
    final ficha = _ficha;
    if (_error != null || ficha == null) {
      return Scaffold(appBar: AppBar(title: Text(titulo)), body: ErrorState(mensaje: _error ?? 'No se pudo cargar.', onRetry: _cargar));
    }

    final scheme = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    Widget dato(String etiqueta, String valor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(etiqueta, style: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant))),
              Text(valor, style: texto.bodyMedium),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Historial en este local', style: texto.titleSmall),
                const SizedBox(height: 8),
                dato('Citas completadas', '${ficha.totalCitas}'),
                dato('Primera cita', ficha.primeraCitaAt == null ? '-' : AppFormatters.fechaCorta(ficha.primeraCitaAt!)),
                dato('Última cita', ficha.ultimaCitaAt == null ? '-' : AppFormatters.fechaCorta(ficha.ultimaCitaAt!)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('Confiabilidad (solo staff)', style: texto.titleSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Cuenta toda la plataforma, no solo este local. El cliente no ve estos datos.',
                  style: texto.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                dato('No-shows', '${ficha.noShows}'),
                dato('Cancelaciones tardías', '${ficha.cancelacionesTardias}'),
                if (ficha.requiereConfirmacion)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Sus citas nacen confirmadas, sin el respiro del hold (3 o más no-shows).',
                      style: texto.bodySmall?.copyWith(color: scheme.error),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Preferencias', style: texto.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _notaCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Nota del cliente',
              hintText: 'Ej. Fade 2 a los lados, tijera arriba',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _preferidoId,
            decoration: const InputDecoration(labelText: 'Profesional preferido'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Sin preferencia')),
              ..._profesionales.map((p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.alias ?? p.nombre))),
            ],
            onChanged: (v) => setState(() => _preferidoId = v),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Guardar ficha', onPressed: _guardar, isLoading: _guardando),
        ],
      ),
    );
  }
}
