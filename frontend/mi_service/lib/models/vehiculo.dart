class Vehiculo {
  final int id;
  final String placa;
  final String marca;
  final String modelo;
  final int anio;
  final int capacidad;
  final double kilometraje;
  final String estado; // DISPONIBLE, EN_RUTA, EN_MANTENIMIENTO

  Vehiculo({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.capacidad,
    required this.kilometraje,
    required this.estado,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'] ?? 0,
      placa: json['placa'] ?? '',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      anio: json['año'] ?? json['anio'] ?? json['idAnio'] ?? 0,
      capacidad: json['capacidad'] ?? 0,
      kilometraje: (json['kilometraje'] ?? json['km'] ?? 0).toDouble(),
      estado: json['estado'] ?? 'DESCONOCIDO',
    );
  }
}