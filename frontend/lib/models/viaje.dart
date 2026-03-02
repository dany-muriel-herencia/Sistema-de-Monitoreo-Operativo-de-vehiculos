class Viaje {
  final String id;
  final String conductorId;
  final String vehiculoId;
  final String rutaId;
  final String estado;

  Viaje({
    required this.id,
    required this.conductorId,
    required this.vehiculoId,
    required this.rutaId,
    required this.estado,
  });

  factory Viaje.fromJson(Map<String, dynamic> json) {
    return Viaje(
      id: json['id']?.toString() ?? '',
      conductorId: json['conductor_id']?.toString() ?? '',
      vehiculoId: json['vehiculo_id']?.toString() ?? '',
      rutaId: json['ruta_id']?.toString() ?? '',
      estado: json['estado_nombre'] ?? json['estado'] ?? 'PLANIFICADO',
    );
  }
}
