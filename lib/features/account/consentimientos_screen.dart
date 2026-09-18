import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../data/models/identity_models.dart';
import '../../state/repository_providers.dart';

/// Consentimientos por finalidad (§13.1): nunca "aceptar todo" con un solo
/// toque — cada finalidad es su propia decisión, tal como exige la LOPDP.
class ConsentimientosScreen extends ConsumerStatefulWidget {
  const ConsentimientosScreen({super.key});

  @override
  ConsumerState<ConsentimientosScreen> createState() => _ConsentimientosScreenState();
}

class _ConsentimientosScreenState extends ConsumerState<ConsentimientosScreen> {
  bool _cargando = true;
  String? _error;
  Map<String, Consentimiento> _porFinalidad = {};
  final Set<String> _procesando = {};

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
      final lista = await ref.read(identityRepositoryProvider).obtenerConsentimientos();
      if (!mounted) return;
      setState(() => _porFinalidad = {for (final c in lista) c.finalidad: c});
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _alternar(String finalidad, bool nuevoValor) async {
    setState(() => _procesando.add(finalidad));
    try {
      final actualizado =
          await ref.read(identityRepositoryProvider).otorgarOrevocar(finalidad: finalidad, otorgado: nuevoValor);
      if (mounted) setState(() => _porFinalidad[finalidad] = actualizado);
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _procesando.remove(finalidad));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad y consentimientos')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(mensaje: _error!, onRetry: _cargar)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: finalidadesConsentimiento.map((f) {
                    final actual = _porFinalidad[f];
                    final otorgado = actual?.otorgado ?? false;
                    final esObligatoria = f == 'operacion_servicio';
                    return Card(
                      child: SwitchListTile(
                        title: Text(etiquetaFinalidad(f)),
                        subtitle: esObligatoria
                            ? const Text('Necesario para poder agendar y operar tus citas')
                            : null,
                        value: otorgado,
                        onChanged: _procesando.contains(f) || esObligatoria
                            ? null
                            : (v) => _alternar(f, v),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
