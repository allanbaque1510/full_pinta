// Modelos del módulo Reviews (§4.8): reseñas y reportes.

class Resena {
  final String id;
  final String citaId;
  final String localId;
  final String profesionalId;
  final int puntajeLocal;
  final int? puntajeProfesional;
  final int? puntualidad;
  final int? limpieza;
  final String? comentario;
  final String estado; // publicada | en_revision | oculta
  final String? respuestaLocal;
  final DateTime? respuestaAt;
  final DateTime? createdAt;

  const Resena({
    required this.id,
    required this.citaId,
    required this.localId,
    required this.profesionalId,
    required this.puntajeLocal,
    this.puntajeProfesional,
    this.puntualidad,
    this.limpieza,
    this.comentario,
    required this.estado,
    this.respuestaLocal,
    this.respuestaAt,
    this.createdAt,
  });

  factory Resena.fromJson(Map<String, dynamic> json) => Resena(
        id: json['id'] as String,
        citaId: json['cita_id'] as String,
        localId: json['local_id'] as String,
        profesionalId: json['profesional_id'] as String,
        puntajeLocal: json['puntaje_local'] as int,
        puntajeProfesional: json['puntaje_profesional'] as int?,
        puntualidad: json['puntualidad'] as int?,
        limpieza: json['limpieza'] as int?,
        comentario: json['comentario'] as String?,
        estado: json['estado'] as String? ?? 'publicada',
        respuestaLocal: json['respuesta_local'] as String?,
        respuestaAt: json['respuesta_at'] == null ? null : DateTime.tryParse(json['respuesta_at']),
        createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at']),
      );
}

String textoEstadoResena(String estado) {
  switch (estado) {
    case 'publicada':
      return 'Publicada';
    case 'en_revision':
      return 'En revisión';
    case 'oculta':
      return 'Oculta';
    default:
      return estado;
  }
}

const tiposReportables = ['resena', 'foto', 'local', 'profesional'];
const motivosReporte = ['difamacion', 'contenido_inapropiado', 'falso', 'spam', 'otro'];

String etiquetaMotivoReporte(String motivo) {
  switch (motivo) {
    case 'difamacion':
      return 'Difamación';
    case 'contenido_inapropiado':
      return 'Contenido inapropiado';
    case 'falso':
      return 'Información falsa';
    case 'spam':
      return 'Spam';
    default:
      return 'Otro';
  }
}
