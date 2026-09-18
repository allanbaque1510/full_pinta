// Modelos del módulo Staffing (§4.6): profesional, asignación, turnos,
// recursos, habilidades, excepciones.

import '../../core/utils/json_num.dart';

class Profesional {
  final String id;
  final String nombre;
  final String? alias;
  final String? bio;
  final String? fotoUrl;
  final bool independiente;
  final bool perfilPublico;
  final int traslacionMin;
  final bool tieneCuentaPropia;

  const Profesional({
    required this.id,
    required this.nombre,
    this.alias,
    this.bio,
    this.fotoUrl,
    required this.independiente,
    required this.perfilPublico,
    required this.traslacionMin,
    required this.tieneCuentaPropia,
  });

  factory Profesional.fromJson(Map<String, dynamic> json) => Profesional(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        alias: json['alias'] as String?,
        bio: json['bio'] as String?,
        fotoUrl: json['foto_url'] as String?,
        independiente: json['independiente'] as bool? ?? false,
        perfilPublico: json['perfil_publico'] as bool? ?? true,
        traslacionMin: json['traslado_min'] as int? ?? 30,
        tieneCuentaPropia: json['tiene_cuenta_propia'] as bool? ?? false,
      );
}

class ProfesionalFoto {
  final String id;
  final String profesionalId;
  final String url;
  final int orden;

  const ProfesionalFoto({
    required this.id,
    required this.profesionalId,
    required this.url,
    required this.orden,
  });

  factory ProfesionalFoto.fromJson(Map<String, dynamic> json) => ProfesionalFoto(
        id: json['id'] as String,
        profesionalId: json['profesional_id'] as String,
        url: json['url'] as String,
        orden: json['orden'] as int? ?? 0,
      );
}

class ProfesionalServicioResumen {
  final String id;
  final String profesionalId;
  final String servicioLocalId;
  final String servicioNombre;
  final String? precioOverride;

  const ProfesionalServicioResumen({
    required this.id,
    required this.profesionalId,
    required this.servicioLocalId,
    required this.servicioNombre,
    this.precioOverride,
  });

  factory ProfesionalServicioResumen.fromJson(Map<String, dynamic> json) =>
      ProfesionalServicioResumen(
        id: json['id'] as String,
        profesionalId: json['profesional_id'] as String,
        servicioLocalId: json['servicio_local_id'] as String,
        servicioNombre: json['servicio_nombre'] as String? ?? '',
        precioOverride: json['precio_override']?.toString(),
      );
}

class ResenasResumenProfesional {
  final double promedio;
  final int total;

  const ResenasResumenProfesional({required this.promedio, required this.total});

  factory ResenasResumenProfesional.fromJson(Map<String, dynamic> json) =>
      ResenasResumenProfesional(
        promedio: numDeJson(json['promedio']),
        total: json['total'] as int? ?? 0,
      );
}

/// `GET /profesionales/{id}/perfil-publico`.
class ProfesionalPerfilPublico {
  final String id;
  final String nombre;
  final String? alias;
  final String? bio;
  final String? fotoUrl;
  final List<ProfesionalFoto> fotos;
  final List<ProfesionalServicioResumen> servicios;
  final ResenasResumenProfesional resenas;
  final bool esFavorito;

  const ProfesionalPerfilPublico({
    required this.id,
    required this.nombre,
    this.alias,
    this.bio,
    this.fotoUrl,
    required this.fotos,
    required this.servicios,
    required this.resenas,
    this.esFavorito = false,
  });

  factory ProfesionalPerfilPublico.fromJson(Map<String, dynamic> json) => ProfesionalPerfilPublico(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        alias: json['alias'] as String?,
        bio: json['bio'] as String?,
        fotoUrl: json['foto_url'] as String?,
        fotos: (json['fotos'] as List<dynamic>? ?? [])
            .map((e) => ProfesionalFoto.fromJson(e as Map<String, dynamic>))
            .toList(),
        servicios: (json['servicios'] as List<dynamic>? ?? [])
            .map((e) => ProfesionalServicioResumen.fromJson(e as Map<String, dynamic>))
            .toList(),
        resenas: ResenasResumenProfesional.fromJson(json['resenas'] as Map<String, dynamic>? ?? {}),
        esFavorito: json['es_favorito'] as bool? ?? false,
      );
}

const rolesStaffing = ['barbero', 'estilista', 'manicurista', 'groomer', 'recepcion'];
const modalidadesAsignacion = ['empleado', 'renta_silla', 'invitado'];

String etiquetaRolStaffing(String rol) {
  switch (rol) {
    case 'barbero':
      return 'Barbero';
    case 'estilista':
      return 'Estilista';
    case 'manicurista':
      return 'Manicurista';
    case 'groomer':
      return 'Groomer';
    case 'recepcion':
      return 'Recepción';
    default:
      return rol;
  }
}

class Asignacion {
  final String id;
  final String localId;
  final String profesionalId;
  final String? profesionalNombre;
  final String rol;
  final String modalidad;
  final String comisionPct;
  final String desde;
  final String? hasta;

  const Asignacion({
    required this.id,
    required this.localId,
    required this.profesionalId,
    this.profesionalNombre,
    required this.rol,
    required this.modalidad,
    required this.comisionPct,
    required this.desde,
    this.hasta,
  });

  bool get vigente => hasta == null;

  factory Asignacion.fromJson(Map<String, dynamic> json) => Asignacion(
        id: json['id'] as String,
        localId: json['local_id'] as String,
        profesionalId: json['profesional_id'] as String,
        profesionalNombre: json['profesional_nombre'] as String?,
        rol: json['rol'] as String,
        modalidad: json['modalidad'] as String,
        comisionPct: json['comision_pct']?.toString() ?? '0',
        desde: json['desde'] as String,
        hasta: json['hasta'] as String?,
      );
}

class Turno {
  final String id;
  final String asignacionId;
  final String profesionalId;
  final String localId;
  final int diaSemana;
  final String entra;
  final String sale;
  final String vigenteDesde;
  final String? vigenteHasta;

  const Turno({
    required this.id,
    required this.asignacionId,
    required this.profesionalId,
    required this.localId,
    required this.diaSemana,
    required this.entra,
    required this.sale,
    required this.vigenteDesde,
    this.vigenteHasta,
  });

  factory Turno.fromJson(Map<String, dynamic> json) => Turno(
        id: json['id'] as String,
        asignacionId: json['asignacion_id'] as String,
        profesionalId: json['profesional_id'] as String,
        localId: json['local_id'] as String,
        diaSemana: json['dia_semana'] as int,
        entra: json['entra'] as String,
        sale: json['sale'] as String,
        vigenteDesde: json['vigente_desde'] as String,
        vigenteHasta: json['vigente_hasta'] as String?,
      );
}

const tiposTurnoFecha = ['extra', 'reemplaza', 'cancela'];

class TurnoFecha {
  final String id;
  final String profesionalId;
  final String localId;
  final String fecha;
  final String tipo;
  final String? entra;
  final String? sale;
  final String? nota;

  const TurnoFecha({
    required this.id,
    required this.profesionalId,
    required this.localId,
    required this.fecha,
    required this.tipo,
    this.entra,
    this.sale,
    this.nota,
  });

  factory TurnoFecha.fromJson(Map<String, dynamic> json) => TurnoFecha(
        id: json['id'] as String,
        profesionalId: json['profesional_id'] as String,
        localId: json['local_id'] as String,
        fecha: json['fecha'] as String,
        tipo: json['tipo'] as String,
        entra: json['entra'] as String?,
        sale: json['sale'] as String?,
        nota: json['nota'] as String?,
      );
}

const tiposRecurso = ['silla', 'mesa_unas', 'lavacabezas', 'tina', 'box_privado'];

String etiquetaTipoRecurso(String tipo) {
  switch (tipo) {
    case 'silla':
      return 'Silla';
    case 'mesa_unas':
      return 'Mesa de uñas';
    case 'lavacabezas':
      return 'Lavacabezas';
    case 'tina':
      return 'Tina';
    case 'box_privado':
      return 'Box privado';
    case 'ninguno':
      return 'Ninguno';
    default:
      return tipo;
  }
}

class Recurso {
  final String id;
  final String localId;
  final String tipo;
  final String nombre;
  final bool activo;

  const Recurso({
    required this.id,
    required this.localId,
    required this.tipo,
    required this.nombre,
    required this.activo,
  });

  factory Recurso.fromJson(Map<String, dynamic> json) => Recurso(
        id: json['id'] as String,
        localId: json['local_id'] as String,
        tipo: json['tipo'] as String,
        nombre: json['nombre'] as String,
        activo: json['activo'] as bool? ?? true,
      );
}

class Habilidad {
  final String id;
  final String profesionalId;
  final String servicioLocalId;
  final String servicioNombre;
  final String? precioOverride;

  const Habilidad({
    required this.id,
    required this.profesionalId,
    required this.servicioLocalId,
    required this.servicioNombre,
    this.precioOverride,
  });

  factory Habilidad.fromJson(Map<String, dynamic> json) => Habilidad(
        id: json['id'] as String,
        profesionalId: json['profesional_id'] as String,
        servicioLocalId: json['servicio_local_id'] as String,
        servicioNombre: json['servicio_nombre'] as String? ?? '',
        precioOverride: json['precio_override']?.toString(),
      );
}

const motivosExcepcion = ['feriado', 'vacaciones', 'mantenimiento', 'personal', 'bloqueo_manual'];

String etiquetaMotivoExcepcion(String motivo) {
  switch (motivo) {
    case 'feriado':
      return 'Feriado';
    case 'vacaciones':
      return 'Vacaciones';
    case 'mantenimiento':
      return 'Mantenimiento';
    case 'personal':
      return 'Personal';
    case 'bloqueo_manual':
      return 'Bloqueo manual';
    default:
      return motivo;
  }
}

class Excepcion {
  final String id;
  final String? localId;
  final String? profesionalId;
  final String? recursoId;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String motivo;
  final String? nota;

  const Excepcion({
    required this.id,
    this.localId,
    this.profesionalId,
    this.recursoId,
    required this.fechaInicio,
    required this.fechaFin,
    required this.motivo,
    this.nota,
  });

  factory Excepcion.fromJson(Map<String, dynamic> json) => Excepcion(
        id: json['id'] as String,
        localId: json['local_id'] as String?,
        profesionalId: json['profesional_id'] as String?,
        recursoId: json['recurso_id'] as String?,
        fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
        fechaFin: DateTime.parse(json['fecha_fin'] as String),
        motivo: json['motivo'] as String,
        nota: json['nota'] as String?,
      );
}
