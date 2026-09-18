import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/list_scaffold.dart';
import '../../data/models/staffing_models.dart';
import '../../state/repository_providers.dart';

class ProfesionalesListScreen extends ConsumerStatefulWidget {
  final String localId;

  const ProfesionalesListScreen({super.key, required this.localId});

  @override
  ConsumerState<ProfesionalesListScreen> createState() => _ProfesionalesListScreenState();
}

class _ProfesionalesListScreenState extends ConsumerState<ProfesionalesListScreen> {
  AsyncValue<List<Profesional>> _profesionales = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _profesionales = const AsyncValue.loading());
    try {
      final lista = await ref.read(staffingRepositoryProvider).listarProfesionales(widget.localId);
      if (mounted) setState(() => _profesionales = AsyncValue.data(lista));
    } catch (e, st) {
      if (mounted) setState(() => _profesionales = AsyncValue.error(DioClient.mapearError(e), st));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScaffold<Profesional>(
      titulo: 'Personal',
      items: _profesionales,
      onRetry: _cargar,
      onCrear: () async {
        await context.push('/locales/${widget.localId}/personal/nuevo');
        _cargar();
      },
      mensajeVacio: 'Todavía no das de alta a nadie.',
      iconoVacio: Icons.people_outline,
      itemBuilder: (context, p) => CrudTile(
        icono: Icons.person_outline,
        titulo: p.alias ?? p.nombre,
        subtitulo: p.tieneCuentaPropia ? 'Tiene cuenta propia' : 'Gestionado por el local',
        onTap: () => context
            .push('/profesionales/${p.id}/admin', extra: widget.localId)
            .then((_) => _cargar()),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
