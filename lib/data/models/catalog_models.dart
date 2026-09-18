// Catálogo maestro de la plataforma (§4.5) — nunca texto libre.

class CategoriaServicio {
  final String id;
  final String vertical;
  final String codigo;
  final String nombre;
  final String? icono;
  final int orden;

  const CategoriaServicio({
    required this.id,
    required this.vertical,
    required this.codigo,
    required this.nombre,
    this.icono,
    required this.orden,
  });

  factory CategoriaServicio.fromJson(Map<String, dynamic> json) => CategoriaServicio(
        id: json['id'] as String,
        vertical: json['vertical'] as String,
        codigo: json['codigo'] as String,
        nombre: json['nombre'] as String,
        icono: json['icono'] as String?,
        orden: json['orden'] as int? ?? 0,
      );
}

const verticalesDisponibles = ['barberia', 'estetica', 'unas', 'mascotas'];

String etiquetaVertical(String codigo) {
  switch (codigo) {
    case 'barberia':
      return 'Barbería';
    case 'estetica':
      return 'Estética';
    case 'unas':
      return 'Uñas';
    case 'mascotas':
      return 'Mascotas';
    default:
      return codigo;
  }
}

/// `GET /catalogo/servicios` — servicio maestro, punto de partida para dar
/// de alta un `ServicioLocal`.
class CatalogoServicio {
  final String id;
  final String vertical;
  final String categoriaCodigo;
  final String nombre;
  final String slug;
  final int duracionBaseMin;
  final String tipoRecurso;

  const CatalogoServicio({
    required this.id,
    required this.vertical,
    required this.categoriaCodigo,
    required this.nombre,
    required this.slug,
    required this.duracionBaseMin,
    required this.tipoRecurso,
  });

  factory CatalogoServicio.fromJson(Map<String, dynamic> json) => CatalogoServicio(
        id: json['id'] as String,
        vertical: json['vertical'] as String,
        categoriaCodigo: json['categoria_codigo'] as String,
        nombre: json['nombre'] as String,
        slug: json['slug'] as String,
        duracionBaseMin: json['duracion_base_min'] as int? ?? 30,
        tipoRecurso: json['tipo_recurso'] as String? ?? 'ninguno',
      );
}

/// Precio y duración que un local concreto fija sobre un `CatalogoServicio`
/// (§4.5). `precio` viaja como string desde la API — ver AppFormatters.dinero.
class ServicioLocal {
  final String id;
  final String localId;
  final String catalogoServicioId;
  final String nombre;
  final String precio;
  final bool precioDesde;
  final int duracionMin;
  final int bufferMin;
  final bool comisionable;
  final bool activo;

  const ServicioLocal({
    required this.id,
    required this.localId,
    required this.catalogoServicioId,
    required this.nombre,
    required this.precio,
    required this.precioDesde,
    required this.duracionMin,
    required this.bufferMin,
    required this.comisionable,
    required this.activo,
  });

  factory ServicioLocal.fromJson(Map<String, dynamic> json) => ServicioLocal(
        id: json['id'] as String,
        localId: json['local_id'] as String,
        catalogoServicioId: json['catalogo_servicio_id'] as String,
        nombre: json['nombre'] as String? ?? '',
        precio: json['precio']?.toString() ?? '0',
        precioDesde: json['precio_desde'] as bool? ?? false,
        duracionMin: json['duracion_min'] as int? ?? 0,
        bufferMin: json['buffer_min'] as int? ?? 0,
        comisionable: json['comisionable'] as bool? ?? true,
        activo: json['activo'] as bool? ?? true,
      );
}

class Producto {
  final String id;
  final String localId;
  final String nombre;
  final String precio;
  final String comisionPct;
  final bool activo;

  const Producto({
    required this.id,
    required this.localId,
    required this.nombre,
    required this.precio,
    required this.comisionPct,
    required this.activo,
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        id: json['id'] as String,
        localId: json['local_id'] as String,
        nombre: json['nombre'] as String,
        precio: json['precio']?.toString() ?? '0',
        comisionPct: json['comision_pct']?.toString() ?? '0',
        activo: json['activo'] as bool? ?? true,
      );
}

class SolicitudCatalogo {
  final String id;
  final String localId;
  final String vertical;
  final String nombrePropuesto;
  final String? descripcion;
  final String estado; // pendiente | aprobada | rechazada
  final String? motivoRechazo;

  const SolicitudCatalogo({
    required this.id,
    required this.localId,
    required this.vertical,
    required this.nombrePropuesto,
    this.descripcion,
    required this.estado,
    this.motivoRechazo,
  });

  factory SolicitudCatalogo.fromJson(Map<String, dynamic> json) => SolicitudCatalogo(
        id: json['id'] as String,
        localId: json['local_id'] as String,
        vertical: json['vertical'] as String,
        nombrePropuesto: json['nombre_propuesto'] as String,
        descripcion: json['descripcion'] as String?,
        estado: json['estado'] as String? ?? 'pendiente',
        motivoRechazo: json['motivo_rechazo'] as String?,
      );
}
