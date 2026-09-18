import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/repository_providers.dart';

/// `POST /locales/{id}/esperas` — anotarse cuesta poco y convierte
/// cancelaciones en citas (§4.7). `desde`/`hasta` son opcionales: acotan la
/// franja horaria que le sirve al cliente, para no avisarle de un cupo a
/// las 8am si solo puede en la tarde.
Future<bool?> mostrarEsperaDialog(
  BuildContext context, {
  required String localId,
  required String servicioLocalId,
  required String fechaDeseada,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _EsperaDialog(
      localId: localId,
      servicioLocalId: servicioLocalId,
      fechaDeseada: fechaDeseada,
    ),
  );
}

enum _Preferencia { cualquiera, tarde, noche }

class _EsperaDialog extends ConsumerStatefulWidget {
  final String localId;
  final String servicioLocalId;
  final String fechaDeseada;

  const _EsperaDialog({
    required this.localId,
    required this.servicioLocalId,
    required this.fechaDeseada,
  });

  @override
  ConsumerState<_EsperaDialog> createState() => _EsperaDialogState();
}

class _EsperaDialogState extends ConsumerState<_EsperaDialog> {
  bool _cargando = false;
  _Preferencia _preferencia = _Preferencia.cualquiera;

  (String?, String?) get _rangoHorario => switch (_preferencia) {
        _Preferencia.cualquiera => (null, null),
        _Preferencia.tarde => ('14:00', '18:00'),
        _Preferencia.noche => ('18:00', null),
      };

  Future<void> _confirmar() async {
    setState(() => _cargando = true);
    try {
      final (desde, hasta) = _rangoHorario;
      await ref.read(schedulingRepositoryProvider).anotarseEnEspera(
            widget.localId,
            servicioLocalId: widget.servicioLocalId,
            fechaDeseada: widget.fechaDeseada,
            desde: desde,
            hasta: hasta,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lista de espera'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Te avisamos apenas se libere un cupo ese día para este servicio. No hace falta pagar nada.',
          ),
          const SizedBox(height: 16),
          Text('Preferencia de horario', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Cualquier hora'),
                selected: _preferencia == _Preferencia.cualquiera,
                onSelected: (_) => setState(() => _preferencia = _Preferencia.cualquiera),
              ),
              ChoiceChip(
                label: const Text('Tarde (14-18h)'),
                selected: _preferencia == _Preferencia.tarde,
                onSelected: (_) => setState(() => _preferencia = _Preferencia.tarde),
              ),
              ChoiceChip(
                label: const Text('Noche (18h+)'),
                selected: _preferencia == _Preferencia.noche,
                onSelected: (_) => setState(() => _preferencia = _Preferencia.noche),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        PrimaryButton(label: 'Confirmar en lista', onPressed: _confirmar, isLoading: _cargando),
      ],
    );
  }
}
