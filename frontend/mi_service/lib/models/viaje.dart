class Viaje {
  final int id;
  final int vehiculoId;
  final int conductorId;
  final int rutaId;
  final DateTime? fechaHoraInicio;
  final DateTime? fechaHoraFin;
  final String estado; // PLANIFICADO, EN_CURSO, FINALIZADO

  Viaje({
    required this.id,
    required this.vehiculoId,
    required this.conductorId,
    required this.rutaId,
    this.fechaHoraInicio,
    this.fechaHoraFin,
    required this.estado,
  });

  Viaje copyWith({
    int? id,
    int? vehiculoId,
    int? conductorId,
    int? rutaId,
    DateTime? fechaHoraInicio,
    DateTime? fechaHoraFin,
    String? estado,
  }) {
    return Viaje(
      id: id ?? this.id,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      conductorId: conductorId ?? this.conductorId,
      rutaId: rutaId ?? this.rutaId,
      fechaHoraInicio: fechaHoraInicio ?? this.fechaHoraInicio,
      fechaHoraFin: fechaHoraFin ?? this.fechaHoraFin,
      estado: estado ?? this.estado,
    );
  }

  factory Viaje.fromJson(Map<String, dynamic> json) {
    return Viaje(
      id: int.tryParse(json['id'].toString()) ?? 0,
      vehiculoId: int.tryParse((json['vehiculo_id'] ?? json['idVehiculo'] ?? 0).toString()) ?? 0,
      conductorId: int.tryParse((json['conductor_id'] ?? json['idConductor'] ?? 0).toString()) ?? 0,
      rutaId: int.tryParse((json['ruta_id'] ?? json['idRuta'] ?? 0).toString()) ?? 0,
      fechaHoraInicio: json['fecha_hora_inicio'] != null
          ? DateTime.parse(json['fecha_hora_inicio'])
          : json['fechaInicio'] != null 
            ? DateTime.parse(json['fechaInicio'])
            : null,
      fechaHoraFin: json['fecha_hora_fin'] != null
          ? DateTime.parse(json['fecha_hora_fin'])
          : json['fechaFin'] != null
            ? DateTime.parse(json['fechaFin'])
            : null,
      estado: json['estado'] ?? 'PLANIFICADO',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehiculo_id': vehiculoId,
    'conductor_id': conductorId,
    'ruta_id': rutaId,
    'fecha_hora_inicio': fechaHoraInicio?.toIso8601String(),
    'fecha_hora_fin': fechaHoraFin?.toIso8601String(),
    'estado': estado,
  };
}