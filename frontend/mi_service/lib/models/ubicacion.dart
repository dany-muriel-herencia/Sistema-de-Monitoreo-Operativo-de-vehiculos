class Ubicacion {
  final int viajeId;
  final DateTime timestamp;
  final double latitud;
  final double longitud;
  final double? velocidad;

  Ubicacion({
    required this.viajeId,
    required this.timestamp,
    required this.latitud,
    required this.longitud,
    this.velocidad,
  });

  Map<String, dynamic> toJson() => {
    'viajeId': viajeId,
    'timestamp': timestamp.toIso8601String(),
    'latitud': latitud,
    'longitud': longitud,
    'velocidad': velocidad,
  };
}