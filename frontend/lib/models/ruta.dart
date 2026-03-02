class Ruta {
  final String id;
  final String nombre;
  final double distanciaTotal;
  final int duracionEstimadaMinutos;
  final List<PuntoRuta> puntos;

  Ruta({
    required this.id,
    required this.nombre,
    required this.distanciaTotal,
    required this.duracionEstimadaMinutos,
    this.puntos = const [],
  });

  factory Ruta.fromJson(Map<String, dynamic> json) {
    var puntosList = json['puntos'] as List? ?? [];
    return Ruta(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      distanciaTotal: double.tryParse(json['distancia_total']?.toString() ?? '0') ?? 0.0,
      duracionEstimadaMinutos: int.tryParse(json['duracion_estimada']?.toString() ?? '0') ?? 0,
      puntos: puntosList.map((p) => PuntoRuta.fromJson(p)).toList(),
    );
  }
}

class PuntoRuta {
  final String id;
  final int orden;
  final double latitud;
  final double longitud;

  PuntoRuta({
    required this.id,
    required this.orden,
    required this.latitud,
    required this.longitud,
  });

  factory PuntoRuta.fromJson(Map<String, dynamic> json) {
    return PuntoRuta(
      id: json['id']?.toString() ?? '',
      orden: json['orden'] ?? 0,
      latitud: double.tryParse(json['latitud']?.toString() ?? '0') ?? 0.0,
      longitud: double.tryParse(json['longitud']?.toString() ?? '0') ?? 0.0,
    );
  }
}
