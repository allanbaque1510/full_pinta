import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../../state/repository_providers.dart';
import 'confirm_dialog.dart';

/// Corazón de favorito de un perfil público (local o profesional) — se
/// auto-gestiona: deshabilita el toque y muestra un spinner mientras la
/// petición está en curso, para que un doble-tap no la dispare dos veces.
/// Pasa exactamente uno de `localId`/`profesionalId`.
///
/// El perfil-público no informa si ya es favorito (`api-referencia.md`), así
/// que `esFavoritoInicial` debe salir de cruzar `GET /mis-favoritos` contra
/// el id de este local/profesional — ver `local_perfil_publico_screen.dart`.
class FavoriteButton extends ConsumerStatefulWidget {
  final String? localId;
  final String? profesionalId;
  final bool esFavoritoInicial;

  const FavoriteButton({
    super.key,
    this.localId,
    this.profesionalId,
    this.esFavoritoInicial = false,
  }) : assert(localId != null || profesionalId != null, 'Pasa localId o profesionalId');

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool _procesando = false;
  late bool _esFavorito = widget.esFavoritoInicial;

  @override
  void didUpdateWidget(FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.esFavoritoInicial != widget.esFavoritoInicial) {
      _esFavorito = widget.esFavoritoInicial;
    }
  }

  Future<void> _alternar() async {
    setState(() => _procesando = true);
    try {
      final agregado = await ref.read(identityRepositoryProvider).alternarFavorito(
            localId: widget.localId,
            profesionalId: widget.profesionalId,
          );
      if (mounted) {
        setState(() => _esFavorito = agregado);
        mostrarMensaje(context, agregado ? 'Agregado a favoritos' : 'Quitado de favoritos');
      }
    } catch (e) {
      if (mounted) mostrarError(context, DioClient.mapearError(e).mensaje);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_procesando) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return IconButton(
      icon: Icon(
        _esFavorito ? Icons.favorite : Icons.favorite_border,
        color: _esFavorito ? Colors.redAccent : null,
      ),
      onPressed: _alternar,
    );
  }
}
