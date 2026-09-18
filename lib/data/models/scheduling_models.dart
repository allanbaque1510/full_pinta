// Modelos del módulo Scheduling (§4.7, §6): disponibilidad, citas, espera.

/// `GET /locales/{id}/disponibilidad` — un candidato de slot cada 15 min.
class SlotDisponible {
  final String profesionalId;
  final String? recursoId;
  final DateTime inicio;
  final DateTime fin;

  const SlotDisponible({
    required this.profesionalId,
    this.recursoId,
    required this.inicio,
    required this.fin,
  });

  factory SlotDisponible.fromJson(Map<String, dynamic> json) => SlotDisponible(
        profesionalId: json['profesional_id'] as String,
        recursoId: json['recurso_id'] as String?,
        inicio: DateTime.parse(json['inicio'] as String),
        fin: DateTime.parse(json['fin'] as String),
      );
}

const estadosTerminalesCita = [
  'completada',
  'cancelada_cliente',
  'cancelada_local',
  'no_show',
  'expirada',
  'reagendada',
];

class CitaItem {
  final String id;
  final String servicioLocalId;
  final String precio;
  final int duracionMin;
  final bool comisionable;
  final String comisionPct;

  const CitaItem({
    required this.id,
    required this.servicioLocalId,
    required this.precio,
    required this.duracionMin,
    required this.comisionable,
    required this.comisionPct,
  });

  factory CitaItem.fromJson(Map<String, dynamic> json) => CitaItem(
        id: json['id'] as String,
        servicioLocalId: json['servicio_local_id'] as String,
        precio: json['precio']?.toString() ?? '0',
        duracionMin: json['duracion_min'] as int? ?? 0,
        comisionable: json['comisionable'] as bool? ?? true,
        comisionPct: json['comision_pct']?.toString() ?? '0',
      );
}

class CitaProducto {
  final String id;
  final String productoId;
  final int cantidad;
  final String precio;

  const CitaProducto({
    required this.id,
    required this.productoId,
    required this.cantidad,
    required this.precio,
  });

  factory CitaProducto.fromJson(Map<String, dynamic> json) => CitaProducto(
        id: json['id'] as String,
        productoId: json['producto_id'] as String,
        cantidad: json['cantidad'] as int? ?? 1,
        precio: json['precio']?.toString() ?? '0',
      );
}

class Cita {
  final String id;
  final String localId;
  final String profesionalId;
  final String? recursoId;
  final String clienteId;
  final String? clienteTelefono;
  final DateTime inicio;
  final DateTime fin;
  final String estado;
  final String canal;
  final String precioTotal;
  final String propina;
  final String? metodoPago;
  final bool clienteNuevo;
  final String paraTipo;
  final String? paraNombre;
  final String? mascotaId;
  final String? notaCliente;
  final String codigo;
  final String? reagendadaDeId;
  final DateTime? expiraAt;
  final DateTime? confirmadaAt;
  final DateTime? canceladaAt;
  final DateTime? completadaAt;
  final List<CitaItem> items;
  final List<CitaProducto> productos;

  const Cita({
    required this.id,
    required this.localId,
    required this.profesionalId,
    this.recursoId,
    required this.clienteId,
    this.clienteTelefono,
    required this.inicio,
    required this.fin,
    required this.estado,
    required this.canal,
    required this.precioTotal,
    required this.propina,
    this.metodoPago,
    required this.clienteNuevo,
    required this.paraTipo,
    this.paraNombre,
    this.mascotaId,
    this.notaCliente,
    required this.codigo,
    this.reagendadaDeId,
    this.expiraAt,
    this.confirmadaAt,
    this.canceladaAt,
    this.completadaAt,
    required this.items,
    required this.productos,
  });

  bool get esTerminal => estadosTerminalesCita.contains(estado);

  factory Cita.fromJson(Map<String, dynamic> json) => Cita(
        id: json['id'] as String,
        localId: json['local_id'] as String,
        profesionalId: json['profesional_id'] as String,
        recursoId: json['recurso_id'] as String?,
        clienteId: json['cliente_id'] as String,
        clienteTelefono: json['cliente_telefono'] as String?,
        inicio: DateTime.parse(json['inicio'] as String),
        fin: DateTime.parse(json['fin'] as String),
        estado: json['estado'] as String,
        canal: json['canal'] as String? ?? 'app',
        precioTotal: json['precio_total']?.toString() ?? '0',
        propina: json['propina']?.toString() ?? '0',
        metodoPago: json['metodo_pago'] as String?,
        clienteNuevo: json['cliente_nuevo'] as bool? ?? false,
        paraTipo: json['para_tipo'] as String? ?? 'titular',
        paraNombre: json['para_nombre'] as String?,
        mascotaId: json['mascota_id'] as String?,
        notaCliente: json['nota_cliente'] as String?,
        codigo: json['codigo'] as String? ?? '',
        reagendadaDeId: json['reagendada_de_id'] as String?,
        expiraAt: json['expira_at'] == null ? null : DateTime.tryParse(json['expira_at']),
        confirmadaAt:
            json['confirmada_at'] == null ? null : DateTime.tryParse(json['confirmada_at']),
        canceladaAt: json['cancelada_at'] == null ? null : DateTime.tryParse(json['cancelada_at']),
        completadaAt:
            json['completada_at'] == null ? null : DateTime.tryParse(json['completada_at']),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => CitaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        productos: (json['productos'] as List<dynamic>? ?? [])
            .map((e) => CitaProducto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Espera {
  final String id;
  final String localId;
  final String clienteId;
  final String? profesionalId;
  final String servicioLocalId;
  final String fechaDeseada;
  final String? desde;
  final String? hasta;
  final String estado; // activa | notificada | convertida | expirada

  const Espera({
    required this.id,
    required this.localId,
    required this.clienteId,
    this.profesionalId,
    required this.servicioLocalId,
    required this.fechaDeseada,
    this.desde,
    this.hasta,
    required this.estado,
  });

  factory Espera.fromJson(Map<String, dynamic> json) => Espera(
        id: json['id'] as String,
        localId: json['local_id'] as String,
        clienteId: json['cliente_id'] as String,
        profesionalId: json['profesional_id'] as String?,
        servicioLocalId: json['servicio_local_id'] as String,
        fechaDeseada: json['fecha_deseada'] as String,
        desde: json['desde'] as String?,
        hasta: json['hasta'] as String?,
        estado: json['estado'] as String? ?? 'activa',
      );
}
