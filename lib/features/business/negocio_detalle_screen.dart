import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../data/models/directory_models.dart';
import '../../state/repository_providers.dart';

class NegocioDetalleScreen extends ConsumerStatefulWidget {
  final String negocioId;

  const NegocioDetalleScreen({super.key, required this.negocioId});

  @override
  ConsumerState<NegocioDetalleScreen> createState() => _NegocioDetalleScreenState();
}

class _NegocioDetalleScreenState extends ConsumerState<NegocioDetalleScreen> {
  Negocio? _negocio;
  List<Local> _locales = [];
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
      final repo = ref.read(directoryRepositoryProvider);
      final negocio = await repo.obtenerNegocio(widget.negocioId);
      final locales = await repo.listarLocales(widget.negocioId);
      if (!mounted) return;
      setState(() {
        _negocio = negocio;
        _locales = locales;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _negocio == null) {
      return Scaffold(appBar: AppBar(), body: ErrorState(mensaje: _error ?? 'No se pudo cargar.', onRetry: _cargar));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_negocio!.nombreMarca)),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _locales.isEmpty
            ? EmptyState(
                mensaje: 'Este negocio todavía no tiene locales.',
                icono: Icons.storefront_outlined,
                accion: FilledButton.icon(
                  onPressed: () => context.push('/negocios/${widget.negocioId}/locales/nuevo'),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear local'),
                ),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _locales.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final local = _locales[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: local.estado == 'activo'
                            ? AppColors.exito.withValues(alpha: 0.2)
                            : null,
                        child: const Icon(Icons.storefront_outlined),
                      ),
                      title: Text(local.nombre),
                      subtitle: Text(textoEstadoLocal(local.estado)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/locales/${local.id}/admin'),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/negocios/${widget.negocioId}/locales/nuevo'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo local'),
      ),
    );
  }
}
