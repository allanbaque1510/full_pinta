/// Modelos del módulo Identity (auth, contexto, consentimientos, favoritos).
/// Los shapes siguen exactamente `docs/api-referencia.md`, no el esquema de
/// base de datos crudo.
class Usuario {
  final String id;
  final String telefono;
  final bool telefonoVerificado;
  final String nombre;
  final String? email;
  final bool emailVerificado;
  final String? fotoUrl;
  final String? genero; // m | f | otro | no_decir
  final String? fechaNacimiento; // yyyy-MM-dd

  const Usuario({
    required this.id,
    required this.telefono,
    required this.telefonoVerificado,
    required this.nombre,
    this.email,
    this.emailVerificado = false,
    this.fotoUrl,
    this.genero,
    this.fechaNacimiento,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        telefono: json['telefono'] as String,
        telefonoVerificado: json['telefono_verificado'] as bool? ?? false,
        nombre: json['nombre'] as String? ?? '',
        email: json['email'] as String?,
        emailVerificado: json['email_verificado'] as bool? ?? false,
        fotoUrl: json['foto_url'] as String?,
        genero: json['genero'] as String?,
        fechaNacimiento: json['fecha_nacimiento'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'telefono': telefono,
        'telefono_verificado': telefonoVerificado,
        'nombre': nombre,
        'email': email,
        'email_verificado': emailVerificado,
        'foto_url': fotoUrl,
        'genero': genero,
        'fecha_nacimiento': fechaNacimiento,
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

  /// Hueco del contrato: `GET /auth/contexto` todavía no lo devuelve; se lee
  /// si el backend lo agrega (`profesional_id`) en contextos de tipo profesional.
  final String? profesionalId;

  const ContextoItem({
    required this.tipo,
    required this.rol,
    this.negocioId,
    this.negocioNombre,
    this.localId,
    this.localNombre,
    this.profesionalId,
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
        profesionalId: json['profesional_id'] as String?,
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
  final String? profesionalId;

  const ContextoActivo({
    required this.tipo,
    required this.rol,
    this.negocioId,
    this.negocioNombre,
    this.localId,
    this.localNombre,
    this.profesionalId,
  });

  static const cliente = ContextoActivo(tipo: 'cliente', rol: 'cliente');

  factory ContextoActivo.desdeItem(ContextoItem item) => ContextoActivo(
        tipo: item.tipo,
        rol: item.rol,
        negocioId: item.negocioId,
        negocioNombre: item.negocioNombre,
        localId: item.localId,
        localNombre: item.localNombre,
        profesionalId: item.profesionalId,
      );

  bool get esCliente => tipo == 'cliente';
  bool get esNegocio => tipo == 'negocio';
  bool get esProfesional => tipo == 'profesional';
}

/// Documento legal vigente asociado a una finalidad (§13.1). En el catálogo
/// trae `contenido`/`url`; en `GET /consentimientos` solo `tipo` y `version`.
class DocumentoLegal {
  final String tipo;
  final String version;
  final String? contenido;
  final String? url;

  const DocumentoLegal({required this.tipo, required this.version, this.contenido, this.url});

  factory DocumentoLegal.fromJson(Map<String, dynamic> json) => DocumentoLegal(
        tipo: json['tipo'] as String? ?? '',
        version: json['version']?.toString() ?? '',
        contenido: json['contenido'] as String?,
        url: json['url'] as String?,
      );
}

/// Fila de `GET /finalidades-consentimiento` (pública).
class FinalidadConsentimiento {
  final String codigo;
  final String nombre;
  final String descripcion;
  final bool obligatorio;
  final DocumentoLegal? documentoLegal;

  const FinalidadConsentimiento({
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.obligatorio,
    this.documentoLegal,
  });

  factory FinalidadConsentimiento.fromJson(Map<String, dynamic> json) => FinalidadConsentimiento(
        codigo: json['codigo'] as String,
        nombre: json['nombre'] as String? ?? json['codigo'] as String,
        descripcion: json['descripcion'] as String? ?? '',
        obligatorio: json['obligatorio'] as bool? ?? false,
        documentoLegal: json['documento_legal'] == null
            ? null
            : DocumentoLegal.fromJson(json['documento_legal'] as Map<String, dynamic>),
      );
}

class Consentimiento {
  final String finalidad;
  final bool otorgado;
  final bool vigente;
  final DocumentoLegal? documentoLegal;
  final DateTime? otorgadoAt;
  final DateTime? revocadoAt;

  const Consentimiento({
    required this.finalidad,
    required this.otorgado,
    required this.vigente,
    this.documentoLegal,
    this.otorgadoAt,
    this.revocadoAt,
  });

  factory Consentimiento.fromJson(Map<String, dynamic> json) => Consentimiento(
        finalidad: json['finalidad'] as String,
        otorgado: json['otorgado'] as bool? ?? false,
        vigente: json['vigente'] as bool? ?? false,
        documentoLegal: json['documento_legal'] == null
            ? null
            : DocumentoLegal.fromJson(json['documento_legal'] as Map<String, dynamic>),
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
