import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_state.dart';
import '../../data/models/identity_models.dart';
import '../../state/repository_providers.dart';

/// `GET`/`PUT /mis-preferencias-notificacion`. El envío real (FCM/WhatsApp)
/// todavía no está conectado (ver plan de implementación, Fase 9 —
/// bloqueadores externos), pero esta pantalla no depende de eso: guarda la
/// preferencia igual para cuando se encienda.
class PreferenciasNotificacionScreen extends ConsumerStatefulWidget {
  const PreferenciasNotificacionScreen({super.key});

  @override
  ConsumerState<PreferenciasNotificacionScreen> createState() => _PreferenciasNotificacionScreenState();
}

class _PreferenciasNotificacionScreenState extends ConsumerState<PreferenciasNotificacionScreen> {
  bool _cargando = true;
  String? _error;
  List<PreferenciaNotificacion> _preferencias = [];
  bool _guardando = false;

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
      final lista = await ref.read(identityRepositoryProvider).obtenerPreferenciasNotificacion();
      if (!mounted) return;
      setState(() => _preferencias = lista);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar(int indice, {bool? push, bool? whatsapp}) async {
    final actualizada = _preferencias[indice].copyWith(push: push, whatsapp: whatsapp);
    setState(() {
      _preferencias[indice] = actualizada;
      _guardando = true;
    });
    try {
      await ref.read(identityRepositoryProvider).actualizarPreferenciasNotificacion([actualizada]);
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias de notificación'),
        bottom: _guardando
            ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator())
            : null,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(mensaje: _error!, onRetry: _cargar)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _preferencias.length,
                  itemBuilder: (context, i) {
                    final p = _preferencias[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                etiquetaCategoriaNotificacion(p.categoria),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Push'),
                              value: p.push,
                              onChanged: (v) => _guardar(i, push: v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('WhatsApp'),
                              value: p.whatsapp,
                              onChanged: (v) => _guardar(i, whatsapp: v),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
