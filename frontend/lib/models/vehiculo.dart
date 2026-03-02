class Vehiculo {
  final String id;
  final String marca;
  final String placa;
  final String modelo;
  final int capacidad;
  final double kilometraje;
  final String estado;
  final int anio;

  Vehiculo({
    required this.id,
    required this.marca,
    required this.placa,
    required this.modelo,
    required this.capacidad,
    required this.kilometraje,
    required this.estado,
    required this.anio,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id']?.toString() ?? '',
      marca: json['marca'] ?? '',
      placa: json['placa'] ?? '',
      modelo: json['modelo'] ?? '',
      capacidad: json['capacidad'] ?? 0,
      kilometraje: (json['kilometraje'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado_nombre'] ?? json['estado'] ?? 'DESCONOCIDO',
      anio: json['anio'] ?? json['año'] ?? 0,
    );
  }
}
