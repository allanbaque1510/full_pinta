import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/multi_select_chips.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/directory_models.dart';
import '../../state/repository_providers.dart';

/// `PUT /locales/{id}/amenidades` reemplaza el conjunto completo — no hay
/// alta/baja individual, se manda la selección final entera cada vez.
class LocalAmenidadesScreen extends ConsumerStatefulWidget {
  final String localId;

  const LocalAmenidadesScreen({super.key, required this.localId});

  @override
  ConsumerState<LocalAmenidadesScreen> createState() => _LocalAmenidadesScreenState();
}

class _LocalAmenidadesScreenState extends ConsumerState<LocalAmenidadesScreen> {
  bool _cargando = true;
  String? _error;
  bool _guardando = false;
  List<Amenidad> _catalogo = [];
  final Set<String> _seleccionadas = {};

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
      final catalogo = await repo.catalogoAmenidades();
      final actuales = await repo.amenidadesDelLocal(widget.localId);
      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
        _seleccionadas
          ..clear()
          ..addAll(actuales.map((a) => a.id));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await ref.read(directoryRepositoryProvider).sincronizarAmenidades(
            widget.localId,
            _seleccionadas.map((id) => {'amenidad_id': id}).toList(),
          );
      if (mounted) mostrarMensaje(context, 'Amenidades actualizadas.');
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: ErrorState(mensaje: _error!, onRetry: _cargar));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Amenidades')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          GroupedMultiSelectChips<Amenidad>(
            opciones: _catalogo,
            seleccionados: _catalogo.where((a) => _seleccionadas.contains(a.id)).toSet(),
            etiqueta: (a) => a.nombre,
            categoria: (a) => a.categoria,
            onChanged: (nuevo) => setState(() {
              _seleccionadas
                ..clear()
                ..addAll(nuevo.map((a) => a.id));
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(label: 'Guardar cambios', onPressed: _guardar, isLoading: _guardando),
        ),
      ),
    );
  }
}
