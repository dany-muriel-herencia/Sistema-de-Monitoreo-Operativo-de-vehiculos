class Conductor {
  final int usuarioId;
  final String nombre;
  final String email;
  final String licencia;
  final String? telefono;
  final double? sueldo;
  final int edad;
  final bool disponible;

  Conductor({
    required this.usuarioId,
    required this.nombre,
    required this.email,
    required this.licencia,
    this.telefono,
    this.sueldo,
    required this.edad,
    required this.disponible,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) {
    return Conductor(
      usuarioId: int.tryParse((json['usuario_id'] ?? json['usuarioId'] ?? json['idUsuario'] ?? json['id'] ?? 0).toString()) ?? 0,
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      licencia: json['licencia'] ?? '',
      telefono: json['telefono']?.toString(), // Lo forzamos a String
      sueldo: double.tryParse((json['sueldo'] ?? 0).toString()) ?? 0.0,
      edad: int.tryParse((json['edad'] ?? 0).toString()) ?? 0,
      disponible: json['disponible'] == 1 || json['disponible'] == true || json['disponible']?.toString().toLowerCase() == 'true',
    );
  }
}