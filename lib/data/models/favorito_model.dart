import '../../core/utils/json_num.dart';

/// `GET /mis-favoritos` / `POST /favoritos` — un favorito es de un local o
/// de un profesional, nunca de ambos (mismo CHECK que la tabla `favorito`,
/// §4.3). El shape de `local`/`profesional` es "el mismo perfil público"
/// (api-referencia.md), pero se parsea de forma tolerante acá: solo se
/// necesitan un par de campos para pintar la tarjeta de favorito, y no vale
/// la pena acoplarse a cada campo de `LocalPerfilPublico` para esta lista.
class Favorito {
  final String id;
  final FavoritoLocal? local;
  final FavoritoProfesional? profesional;
  final DateTime? createdAt;

  const Favorito({required this.id, this.local, this.profesional, this.createdAt});

  bool get esLocal => local != null;

  factory Favorito.fromJson(Map<String, dynamic> json) => Favorito(
        id: json['id'] as String,
        local: json['local'] == null
            ? null
            : FavoritoLocal.fromJson(json['local'] as Map<String, dynamic>),
        profesional: json['profesional'] == null
            ? null
            : FavoritoProfesional.fromJson(json['profesional'] as Map<String, dynamic>),
        createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at']),
      );
}

class FavoritoLocal {
  final String id;
  final String nombre;
  final String? direccion;
  final double? scoreRanking;
  final bool verificado;
  final String? fotoUrl;

  const FavoritoLocal({
    required this.id,
    required this.nombre,
    this.direccion,
    this.scoreRanking,
    this.verificado = false,
    this.fotoUrl,
  });

  factory FavoritoLocal.fromJson(Map<String, dynamic> json) {
    // Si el backend manda el shape completo de perfil-publico, `fotos` trae
    // al menos una entrada con `url` — se toma la primera como miniatura.
    String? primeraFoto;
    final fotos = json['fotos'];
    if (fotos is List && fotos.isNotEmpty && fotos.first is Map) {
      primeraFoto = (fotos.first as Map)['url'] as String?;
    }
    return FavoritoLocal(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String?,
      scoreRanking: numDeJsonOrNull(json['score_ranking']),
      verificado: json['verificado'] as bool? ?? false,
      fotoUrl: primeraFoto,
    );
  }
}

class FavoritoProfesional {
  final String id;
  final String nombre;
  final String? alias;
  final String? fotoUrl;

  const FavoritoProfesional({required this.id, required this.nombre, this.alias, this.fotoUrl});

  factory FavoritoProfesional.fromJson(Map<String, dynamic> json) => FavoritoProfesional(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        alias: json['alias'] as String?,
        fotoUrl: json['foto_url'] as String?,
      );
}
