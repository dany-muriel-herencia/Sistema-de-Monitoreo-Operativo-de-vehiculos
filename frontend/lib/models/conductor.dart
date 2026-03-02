class Conductor {
  final String id;
  final String nombre;
  final String email;
  final String licencia;
  final String telefono;
  final double sueldo;
  final bool disponible;

  Conductor({
    required this.id,
    required this.nombre,
    required this.email,
    required this.licencia,
    required this.telefono,
    required this.sueldo,
    required this.disponible,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      id: json['id'].toString(),
      nombre: json['nombre'],
      email: json['email'],
      licencia: json['licencia'] ?? '',
      telefono: json['telefono']?.toString() ?? '',
      sueldo: (json['sueldo'] as num?)?.toDouble() ?? 0.0,
      disponible: json['disponible'] == 1 || json['disponible'] == true,
    );
  }
}
