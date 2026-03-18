class ApiConstants {
  // ⚠️ IMPORTANTE: Si cambia la IP del PC, actualiza la línea activa.
  // Ejecuta `ipconfig` en la PC para ver tu IP actual de la red LAN.
  //
  // static const String baseUrl = 'http://10.0.2.2:3000/api';      // Emulador Android (AVD)
  static const String baseUrl = 'http://192.168.18.28:3000/api'; // IP LAN actual (dispositivo físico/red WiFi)
  // static const String baseUrl = 'http://127.0.0.1:3000/api';     // Web, Windows desktop o iOS local
  
  static const String login = '$baseUrl/login';
  static const String conductores = '$baseUrl/conductores';
  static const String vehiculos = '$baseUrl/vehiculos';
  static const String viajes = '$baseUrl/viajes';
  static const String ubicaciones = '$baseUrl/ubicaciones';
  static const String reportes = '$baseUrl/reportes';
  static const String rutas = '$baseUrl/rutas';
  static const String incidencias = '$baseUrl/incidencias';
  static const String enums = '$baseUrl/enums';
  static const String alertas = '$baseUrl/alertas';
  static const String eventos = '$baseUrl/eventos';
}


