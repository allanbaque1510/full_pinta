import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_overlay.dart';
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
  List<FinalidadConsentimiento> _finalidades = [];
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
      final repo = ref.read(identityRepositoryProvider);
      final resultados = await Future.wait([repo.obtenerFinalidades(), repo.obtenerConsentimientos()]);
      if (!mounted) return;
      final lista = resultados[1] as List<Consentimiento>;
      setState(() {
        _finalidades = resultados[0] as List<FinalidadConsentimiento>;
        _porFinalidad = {for (final c in lista) c.finalidad: c};
      });
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

  void _leerDocumento(DocumentoLegal doc) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${doc.tipo.replaceAll('_', ' ')} (v${doc.version})'),
        content: SingleChildScrollView(
          child: SelectableText(doc.contenido ?? doc.url ?? 'Documento no disponible.'),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad y consentimientos')),
      body: LoadingOverlay(
        visible: _procesando.isNotEmpty,
        mensaje: 'Guardando cambios...',
        child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(mensaje: _error!, onRetry: _cargar)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _finalidades.map((f) {
                    final otorgado = _porFinalidad[f.codigo]?.otorgado ?? false;
                    final doc = f.documentoLegal;
                    return Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            title: Text(f.nombre),
                            subtitle: Text(
                              f.obligatorio ? '${f.descripcion}\nObligatorio para operar tus citas.' : f.descripcion,
                            ),
                            value: f.obligatorio ? true : otorgado,
                            onChanged: _procesando.contains(f.codigo) || f.obligatorio
                                ? null
                                : (v) => _alternar(f.codigo, v),
                          ),
                          if (doc != null && (doc.contenido != null || doc.url != null))
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 4),
                              child: TextButton.icon(
                                onPressed: () => _leerDocumento(doc),
                                icon: const Icon(Icons.description_outlined, size: 18),
                                label: const Text('Leer documento'),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
      ),
    );
  }
}
