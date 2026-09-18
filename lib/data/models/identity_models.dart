/// Modelos del módulo Identity (auth, contexto, consentimientos, favoritos).
/// Los shapes siguen exactamente `docs/api-referencia.md`, no el esquema de
/// base de datos crudo.
class Usuario {
  final String id;
  final String telefono;
  final bool telefonoVerificado;
  final String nombre;
  final String? email;
  final String? fotoUrl;

  const Usuario({
    required this.id,
    required this.telefono,
    required this.telefonoVerificado,
    required this.nombre,
    this.email,
    this.fotoUrl,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        telefono: json['telefono'] as String,
        telefonoVerificado: json['telefono_verificado'] as bool? ?? false,
        nombre: json['nombre'] as String? ?? '',
        email: json['email'] as String?,
        fotoUrl: json['foto_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'telefono': telefono,
        'telefono_verificado': telefonoVerificado,
        'nombre': nombre,
        'email': email,
        'foto_url': fotoUrl,
      };
}

/// Respuesta de `GET /auth/contexto`: con qué "sombreros" puede entrar
/// este usuario (§3.2).
class ContextoAcceso {
  final String usuarioId;
  final bool esCliente;
  final bool requiereSeleccion;
  final List<ContextoItem> contextos;

  const ContextoAcceso({
    required this.usuarioId,
    required this.esCliente,
    required this.requiereSeleccion,
    required this.contextos,
  });

  factory ContextoAcceso.fromJson(Map<String, dynamic> json) => ContextoAcceso(
        usuarioId: json['usuario_id'] as String,
        esCliente: json['es_cliente'] as bool? ?? true,
        requiereSeleccion: json['requiere_seleccion'] as bool? ?? false,
        contextos: (json['contextos'] as List<dynamic>? ?? [])
            .map((e) => ContextoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// `tipo`: "negocio" | "profesional". Ver api-referencia.md §Identity.
class ContextoItem {
  final String tipo;
  final String rol;
  final String? negocioId;
  final String? negocioNombre;
  final String? localId;
  final String? localNombre;

  const ContextoItem({
    required this.tipo,
    required this.rol,
    this.negocioId,
    this.negocioNombre,
    this.localId,
    this.localNombre,
  });

  bool get esNegocio => tipo == 'negocio';
  bool get esProfesional => tipo == 'profesional';

  /// true si este contexto representa "todos los locales" de un negocio
  /// (negocio_miembro.local_id NULL en el backend).
  bool get todosLosLocales => esNegocio && localId == null;

  factory ContextoItem.fromJson(Map<String, dynamic> json) => ContextoItem(
        tipo: json['tipo'] as String,
        rol: json['rol'] as String,
        negocioId: json['negocio_id'] as String?,
        negocioNombre: json['negocio_nombre'] as String?,
        localId: json['local_id'] as String?,
        localNombre: json['local_nombre'] as String?,
      );
}

/// Un contexto ya elegido y activo en la sesión (lo que el selector guarda).
/// `tipo == 'cliente'` es el default implícito cuando el usuario no elige
/// ninguno de los contextos anteriores (es_cliente siempre es true).
class ContextoActivo {
  final String tipo; // cliente | negocio | profesional
  final String rol;
  final String? negocioId;
  final String? negocioNombre;
  final String? localId;
  final String? localNombre;

  const ContextoActivo({
    required this.tipo,
    required this.rol,
    this.negocioId,
    this.negocioNombre,
    this.localId,
    this.localNombre,
  });

  static const cliente = ContextoActivo(tipo: 'cliente', rol: 'cliente');

  factory ContextoActivo.desdeItem(ContextoItem item) => ContextoActivo(
        tipo: item.tipo,
        rol: item.rol,
        negocioId: item.negocioId,
        negocioNombre: item.negocioNombre,
        localId: item.localId,
        localNombre: item.localNombre,
      );

  bool get esCliente => tipo == 'cliente';
  bool get esNegocio => tipo == 'negocio';
  bool get esProfesional => tipo == 'profesional';
}

const _finalidades = [
  'operacion_servicio',
  'comunicaciones_transaccionales',
  'marketing',
  'transferencia_internacional',
];

List<String> get finalidadesConsentimiento => _finalidades;

String etiquetaFinalidad(String finalidad) {
  switch (finalidad) {
    case 'operacion_servicio':
      return 'Operar mis citas y reservas';
    case 'comunicaciones_transaccionales':
      return 'Comunicaciones sobre mis citas (WhatsApp/push)';
    case 'marketing':
      return 'Promociones y novedades';
    case 'transferencia_internacional':
      return 'Transferencia internacional de datos (WhatsApp/Firebase)';
    default:
      return finalidad;
  }
}

class Consentimiento {
  final String finalidad;
  final bool otorgado;
  final bool vigente;
  final String? documentoVersion;
  final DateTime? otorgadoAt;
  final DateTime? revocadoAt;

  const Consentimiento({
    required this.finalidad,
    required this.otorgado,
    required this.vigente,
    this.documentoVersion,
    this.otorgadoAt,
    this.revocadoAt,
  });

  factory Consentimiento.fromJson(Map<String, dynamic> json) => Consentimiento(
        finalidad: json['finalidad'] as String,
        otorgado: json['otorgado'] as bool? ?? false,
        vigente: json['vigente'] as bool? ?? false,
        documentoVersion: json['documento_version'] as String?,
        otorgadoAt: json['otorgado_at'] == null ? null : DateTime.tryParse(json['otorgado_at']),
        revocadoAt: json['revocado_at'] == null ? null : DateTime.tryParse(json['revocado_at']),
      );
}

class PreferenciaNotificacion {
  final String categoria;
  final bool push;
  final bool whatsapp;

  const PreferenciaNotificacion({
    required this.categoria,
    required this.push,
    required this.whatsapp,
  });

  factory PreferenciaNotificacion.fromJson(Map<String, dynamic> json) => PreferenciaNotificacion(
        categoria: json['categoria'] as String,
        push: json['push'] as bool? ?? true,
        whatsapp: json['whatsapp'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {'categoria': categoria, 'push': push, 'whatsapp': whatsapp};

  PreferenciaNotificacion copyWith({bool? push, bool? whatsapp}) => PreferenciaNotificacion(
        categoria: categoria,
        push: push ?? this.push,
        whatsapp: whatsapp ?? this.whatsapp,
      );
}

String etiquetaCategoriaNotificacion(String codigo) {
  switch (codigo) {
    case 'citas':
      return 'Citas (creación, confirmación, cancelación)';
    case 'agenda':
      return 'Agenda (para profesionales y staff)';
    case 'social':
      return 'Reseñas y respuestas';
    case 'promos':
      return 'Promociones';
    default:
      return codigo;
  }
}
