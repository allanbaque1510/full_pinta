import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_view.dart';
import '../../core/widgets/surface_card.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';
import '../../state/session_controller.dart';

/// Comisiones propias del profesional (§3.2, `GET /profesionales/{id}/liquidaciones`),
/// de todos sus locales mezclados. Solo lectura.
///
/// Hueco del contrato: `GET /auth/contexto` aún no trae `profesional_id`. El id
/// se resuelve de [profesionalId] (si la pantalla que la abre lo conoce), o del
/// contexto activo / de cualquier contexto profesional de la sesión cuando el
/// backend lo incluya. Sin id se muestra un aviso en vez de fallar.
class MisLiquidacionesScreen extends ConsumerStatefulWidget {
  final String? profesionalId;

  const MisLiquidacionesScreen({super.key, this.profesionalId});

  @override
  ConsumerState<MisLiquidacionesScreen> createState() => _MisLiquidacionesScreenState();
}

class _MisLiquidacionesScreenState extends ConsumerState<MisLiquidacionesScreen> {
  AsyncValue<List<Liquidacion>> _liquidaciones = const AsyncValue.loading();
  String? _profesionalId;

  @override
  void initState() {
    super.initState();
    _profesionalId = _resolverProfesionalId();
    if (_profesionalId != null) _cargar();
  }

  String? _resolverProfesionalId() {
    if (widget.profesionalId != null) return widget.profesionalId;
    final sesion = ref.read(sessionControllerProvider);
    final activo = sesion.contextoActivo?.profesionalId;
    if (activo != null) return activo;
    for (final c in sesion.contextoAcceso?.contextos ?? const []) {
      if (c.esProfesional && c.profesionalId != null) return c.profesionalId;
    }
    return null;
  }

  Future<void> _cargar() async {
    setState(() => _liquidaciones = const AsyncValue.loading());
    try {
      final lista = await ref.read(staffingRepositoryProvider).misLiquidaciones(_profesionalId!);
      if (mounted) setState(() => _liquidaciones = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _liquidaciones = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis liquidaciones')),
      body: _profesionalId == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No pudimos identificar tu perfil de profesional todavía. '
                  'Cuando el local vincule tu cuenta, aquí verás tus comisiones.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              child: AsyncValueView<List<Liquidacion>>(
                value: _liquidaciones,
                onRetry: _cargar,
                estaVacio: (data) => data.isEmpty,
                mensajeVacio: 'Todavía no tienes liquidaciones.',
                iconoVacio: Icons.receipt_long_outlined,
                builder: (context, data) => ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _TarjetaLiquidacion(liquidacion: data[i]),
                ),
              ),
            ),
    );
  }
}

class _TarjetaLiquidacion extends StatelessWidget {
  final Liquidacion liquidacion;

  const _TarjetaLiquidacion({required this.liquidacion});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final l = liquidacion;

    Widget fila(String etiqueta, String valor, {bool destacado = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  etiqueta,
                  style: (destacado ? texto.titleSmall : texto.bodyMedium)?.copyWith(
                    color: destacado ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(valor, style: destacado ? texto.titleMedium?.copyWith(color: scheme.primary) : texto.bodyMedium),
            ],
          ),
        );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_fecha(l.periodoDesde)} - ${_fecha(l.periodoHasta)}',
                  style: texto.titleMedium,
                ),
              ),
              Chip(
                label: Text(textoEstadoLiquidacion(l.estado)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // En plan Free el backend omite el desglose: solo se ve el total.
          if (l.tieneDesglose) ...[
            if (l.totalServicios != null) fila('Servicios', AppFormatters.dinero(l.totalServicios)),
            if (l.comisionServicios != null) fila('Comisión por servicios', AppFormatters.dinero(l.comisionServicios)),
            if (l.totalProductos != null) fila('Productos', AppFormatters.dinero(l.totalProductos)),
            if (l.comisionProductos != null) fila('Comisión por productos', AppFormatters.dinero(l.comisionProductos)),
          ],
          fila('Propinas', AppFormatters.dinero(l.totalPropinas)),
          const Divider(height: 20),
          fila('Total a pagar', AppFormatters.dinero(l.totalAPagar), destacado: true),
        ],
      ),
    );
  }

  String _fecha(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : AppFormatters.fechaCorta(d);
  }
}
