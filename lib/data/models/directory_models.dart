import '../../core/utils/json_num.dart';
import 'catalog_models.dart';

class Negocio {
  final String id;
  final String nombreMarca;
  final String? ruc;
  final String plan;

  const Negocio({required this.id, required this.nombreMarca, this.ruc, required this.plan});

  factory Negocio.fromJson(Map<String, dynamic> json) => Negocio(
        id: json['id'] as String,
        nombreMarca: json['nombre_marca'] as String,
        ruc: json['ruc'] as String?,
        plan: json['plan'] as String? ?? 'free',
      );
}

class Local {
  final String id;
  final String negocioId;
  final String nombre;
  final String direccion;
  final String? referencia;
  final double lat;
  final double lng;
  final String? telefono;
  final String? whatsapp;
  final bool verificado;
  final String estado; // borrador | activo | pausado | suspendido
  final int leadTimeMin;
  final int horizonteDias;
  final int politicaCancelacionHoras;

  const Local({
    required this.id,
    required this.negocioId,
    required this.nombre,
    required this.direccion,
    this.referencia,
    required this.lat,
    required this.lng,
    this.telefono,
    this.whatsapp,
    required this.verificado,
    required this.estado,
    required this.leadTimeMin,
    required this.horizonteDias,
    required this.politicaCancelacionHoras,
  });

  factory Local.fromJson(Map<String, dynamic> json) => Local(
        id: json['id'] as String,
        negocioId: json['negocio_id'] as String,
        nombre: json['nombre'] as String,
        direccion: json['direccion'] as String? ?? '',
        referencia: json['referencia'] as String?,
        lat: numDeJson(json['lat']),
        lng: numDeJson(json['lng']),
        telefono: json['telefono'] as String?,
        whatsapp: json['whatsapp'] as String?,
        verificado: json['verificado'] as bool? ?? false,
        estado: json['estado'] as String? ?? 'borrador',
        leadTimeMin: json['lead_time_min'] as int? ?? 60,
        horizonteDias: json['horizonte_dias'] as int? ?? 30,
        politicaCancelacionHoras: json['politica_cancelacion_horas'] as int? ?? 2,
      );
}

String textoEstadoLocal(String estado) {
  switch (estado) {
    case 'borrador':
      return 'Borrador';
    case 'activo':
      return 'Activo';
    case 'pausado':
      return 'Pausado';
    case 'suspendido':
      return 'Suspendido';
    default:
      return estado;
  }
}

/// Resultado de `GET /buscar/locales` — shape más liviano que [Local].
class LocalBusqueda {
  final String id;
  final String negocioId;
  final String nombre;
  final String direccion;
  final double lat;
  final double lng;
  final double distanciaM;
  final String? telefono;
  final String? whatsapp;
  final bool verificado;
  final double scoreRanking;

  const LocalBusqueda({
    required this.id,
    required this.negocioId,
    required this.nombre,
    required this.direccion,
    required this.lat,
    required this.lng,
    required this.distanciaM,
    this.telefono,
    this.whatsapp,
    required this.verificado,
    required this.scoreRanking,
  });

  factory LocalBusqueda.fromJson(Map<String, dynamic> json) => LocalBusqueda(
        id: json['id'] as String,
        negocioId: json['negocio_id'] as String,
        nombre: json['nombre'] as String,
        direccion: json['direccion'] as String? ?? '',
        lat: numDeJson(json['lat']),
        lng: numDeJson(json['lng']),
        distanciaM: numDeJson(json['distancia_m']),
        telefono: json['telefono'] as String?,
        whatsapp: json['whatsapp'] as String?,
        verificado: json['verificado'] as bool? ?? false,
        scoreRanking: numDeJson(json['score_ranking']),
      );
}

class HorarioLocal {
  final String id;
  final String localId;
  final int diaSemana; // 0=domingo .. 6=sábado
  final String abre; // "HH:mm"
  final String cierra;

  const HorarioLocal({
    required this.id,
    required this.localId,
    required this.diaSemana,
    required this.abre,
    required this.cierra,
  });

  factory HorarioLocal.fromJson(Map<String, dynamic> json) => HorarioLocal(
        id: json['id'] as String,
        localId: json['local_id'] as String,
        diaSemana: json['dia_semana'] as int,
        abre: json['abre'] as String,
        cierra: json['cierra'] as String,
      );
}

const nombresDias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

class Amenidad {
  final String id;
  final String codigo;
  final String categoria;
  final String nombre;
  final String? icono;
  final String? detalle;

  const Amenidad({
    required this.id,
    required this.codigo,
    required this.categoria,
    required this.nombre,
    this.icono,
    this.detalle,
  });

  factory Amenidad.fromJson(Map<String, dynamic> json) => Amenidad(
        id: json['id'] as String,
        codigo: json['codigo'] as String,
        categoria: json['categoria'] as String,
        nombre: json['nombre'] as String,
        icono: json['icono'] as String?,
        detalle: json['detalle'] as String?,
      );
}

class LocalFoto {
  final String id;
  final String localId;
  final String url;
  final String tipo; // fachada | interior | trabajo
  final int orden;

  const LocalFoto({
    required this.id,
    required this.localId,
    required this.url,
    required this.tipo,
    required this.orden,
  });

  factory LocalFoto.fromJson(Map<String, dynamic> json) => LocalFoto(
        id: json['id'] as String,
        localId: json['local_id'] as String,
        url: json['url'] as String,
        tipo: json['tipo'] as String,
        orden: json['orden'] as int? ?? 0,
      );
}

class ResenasResumen {
  final double promedio;
  final int total;

  const ResenasResumen({required this.promedio, required this.total});

  factory ResenasResumen.fromJson(Map<String, dynamic> json) => ResenasResumen(
        promedio: numDeJson(json['promedio']),
        total: json['total'] as int? ?? 0,
      );
}

/// `GET /locales/{id}/perfil-publico`.
class LocalPerfilPublico {
  final String id;
  final String nombre;
  final String direccion;
  final String? referencia;
  final double lat;
  final double lng;
  final String? telefono;
  final String? whatsapp;
  final bool verificado;
  final double scoreRanking;
  final int leadTimeMin;
  final int horizonteDias;
  final List<HorarioLocal> horarios;
  final List<ServicioLocal> servicios;
  final List<Amenidad> amenidades;
  final List<LocalFoto> fotos;
  final ResenasResumen resenas;
  final bool esFavorito;

  const LocalPerfilPublico({
    required this.id,
    required this.nombre,
    required this.direccion,
    this.referencia,
    required this.lat,
    required this.lng,
    this.telefono,
    this.whatsapp,
    required this.verificado,
    required this.scoreRanking,
    required this.leadTimeMin,
    required this.horizonteDias,
    required this.horarios,
    required this.servicios,
    required this.amenidades,
    required this.fotos,
    required this.resenas,
    this.esFavorito = false,
  });

  factory LocalPerfilPublico.fromJson(Map<String, dynamic> json) => LocalPerfilPublico(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        direccion: json['direccion'] as String? ?? '',
        referencia: json['referencia'] as String?,
        lat: numDeJson(json['lat']),
        lng: numDeJson(json['lng']),
        telefono: json['telefono'] as String?,
        whatsapp: json['whatsapp'] as String?,
        verificado: json['verificado'] as bool? ?? false,
        scoreRanking: numDeJson(json['score_ranking']),
        leadTimeMin: json['lead_time_min'] as int? ?? 60,
        horizonteDias: json['horizonte_dias'] as int? ?? 30,
        horarios: (json['horarios'] as List<dynamic>? ?? [])
            .map((e) => HorarioLocal.fromJson(e as Map<String, dynamic>))
            .toList(),
        servicios: (json['servicios'] as List<dynamic>? ?? [])
            .map((e) => ServicioLocal.fromJson(e as Map<String, dynamic>))
            .toList(),
        amenidades: (json['amenidades'] as List<dynamic>? ?? [])
            .map((e) => Amenidad.fromJson(e as Map<String, dynamic>))
            .toList(),
        fotos: (json['fotos'] as List<dynamic>? ?? [])
            .map((e) => LocalFoto.fromJson(e as Map<String, dynamic>))
            .toList(),
        resenas: ResenasResumen.fromJson(json['resenas'] as Map<String, dynamic>? ?? {}),
        esFavorito: json['es_favorito'] as bool? ?? false,
      );
}
