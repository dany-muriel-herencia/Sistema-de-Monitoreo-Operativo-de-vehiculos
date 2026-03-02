class ApiConstants {
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Para el emulador de Android
  static const String baseUrl = 'http://127.0.0.1:3000/api'; // Para web, Windows o iOS
  
  static const String login = '$baseUrl/login';
  static const String conductores = '$baseUrl/conductores';
  static const String vehiculos = '$baseUrl/vehiculos';
  static const String viajes = '$baseUrl/viajes';
  static const String ubicaciones = '$baseUrl/ubicaciones';
  static const String reportes = '$baseUrl/reportes';
}
