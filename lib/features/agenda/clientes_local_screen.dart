import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_view.dart';
import '../../data/models/scheduling_models.dart';
import '../../state/repository_providers.dart';

/// Bandeja mensual de clientes del local (`GET /locales/{id}/clientes?mes=`):
/// un cliente por fila con sus visitas completadas en el mes. Al tocar una
/// fila se abre su ficha editable ([FichaClienteScreen], ruta
/// `/locales/:localId/clientes/:usuarioId`). Solo staff (§3.2).
///
/// Pensada también como pestaña "Clientes": no depende de rutas para
/// construirse, solo para abrir la ficha.
class ClientesLocalScreen extends ConsumerStatefulWidget {
  final String localId;

  const ClientesLocalScreen(this.localId, {super.key});

  @override
  ConsumerState<ClientesLocalScreen> createState() => _ClientesLocalScreenState();
}

class _ClientesLocalScreenState extends ConsumerState<ClientesLocalScreen> {
  static final _formatoMes = DateFormat('MMMM yyyy', 'es');

  late DateTime _mes;
  AsyncValue<List<ClienteMes>> _clientes = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    final ahora = AppFormatters.aGuayaquil(DateTime.now());
    _mes = DateTime(ahora.year, ahora.month);
    _cargar();
  }

  String get _mesApi => DateFormat('yyyy-MM').format(_mes);

  bool get _esMesActual {
    final ahora = AppFormatters.aGuayaquil(DateTime.now());
    return _mes.year == ahora.year && _mes.month == ahora.month;
  }

  Future<void> _cargar() async {
    setState(() => _clientes = const AsyncValue.loading());
    try {
      final lista = await ref.read(schedulingRepositoryProvider).clientesDelMes(widget.localId, mes: _mesApi);
      if (mounted) setState(() => _clientes = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _clientes = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  void _cambiarMes(int delta) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + delta));
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final etiquetaMes = _formatoMes.format(_mes);

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Mes anterior',
                  onPressed: () => _cambiarMes(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    etiquetaMes[0].toUpperCase() + etiquetaMes.substring(1),
                    textAlign: TextAlign.center,
                    style: texto.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Mes siguiente',
                  onPressed: _esMesActual ? null : () => _cambiarMes(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: AsyncValueView<List<ClienteMes>>(
                value: _clientes,
                onRetry: _cargar,
                estaVacio: (data) => data.isEmpty,
                mensajeVacio: 'Sin visitas completadas en este mes.',
                iconoVacio: Icons.people_outline,
                builder: (context, data) => ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final c = data[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.onPrimaryContainer,
                          child: Text(c.clienteNombre.isEmpty ? '?' : c.clienteNombre[0].toUpperCase()),
                        ),
                        title: Text(c.clienteNombre),
                        subtitle: Text(
                          [
                            c.visitasEnElMes == 1 ? '1 visita' : '${c.visitasEnElMes} visitas',
                            if (c.ultimaVisita != null) 'última ${AppFormatters.fechaCorta(c.ultimaVisita!)}',
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          '/locales/${widget.localId}/clientes/${c.clienteId}',
                          extra: c.clienteNombre,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
