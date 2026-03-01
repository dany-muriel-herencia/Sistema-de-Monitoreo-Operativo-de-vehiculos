class Alerta {
  final int id;
  final int viajeId;
  final String tipo;
  final DateTime timestamp;
  final String? mensaje;
  final bool resuelta;

  Alerta({
    required this.id,
    required this.viajeId,
    required this.tipo,
    required this.timestamp,
    this.mensaje,
    required this.resuelta,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'],
      viajeId: json['viaje_id'],
      tipo: json['tipo_alerta'] ?? json['tipo'],
      timestamp: DateTime.parse(json['timestamp']),
      mensaje: json['mensaje'],
      resuelta: json['resuelta'] == 1 || json['resuelta'] == true,
    );
  }
}