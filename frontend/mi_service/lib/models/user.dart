class User {
  final int id;
  final String nombre;
  final String email;
  final String rol; // 'admin' o 'conductor'

  User({required this.id, required this.nombre, required this.email, required this.rol});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      rol: (json['rol'] ?? json['role'] ?? 'conductor').toString().toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'rol': rol,
  };
}