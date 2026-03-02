import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

/// Valores válidos que coinciden con los enums del backend.
/// Se obtienen también desde GET /api/enums para no estar duplicados.
class TipoAlerta {
  static const String emergencia = 'EMERGENCIA';
  static const String excesoVelocidad = 'EXCESO_VELOCIDAD';
  static const String fallaMecanica = 'FALLA_MECANICA';
  static const String combustibleBajo = 'COMBUSTIBLE_BAJO';
  static const String perdidaGps = 'PERDIDA_GPS';

  static List<String> get todos => [
        emergencia,
        excesoVelocidad,
        fallaMecanica,
        combustibleBajo,
        perdidaGps,
      ];

  static String label(String value) {
    switch (value) {
      case emergencia: return '🚨 Emergencia';
      case excesoVelocidad: return '⚡ Exceso de Velocidad';
      case fallaMecanica: return '🔧 Falla Mecánica';
      case combustibleBajo: return '⛽ Combustible Bajo';
      case perdidaGps: return '📡 Pérdida de GPS';
      default: return value;
    }
  }
}

class TipoEvento {
  static const String excesovelocidad = 'Exceso de Velocidad';
  static const String fallaMecanica = 'FALLA_MECANICA';
  static const String emergencia = 'EMERGENCIA';
  static const String paradaNoProgramada = 'Parada No Programada';
  static const String desviacionRuta = 'Desviacion de Ruta';
  static const String otro = 'Otro';
}

// Mapa de TipoAlerta → TipoEvento correspondiente
const Map<String, String> tipoAlertaAEvento = {
  TipoAlerta.emergencia: TipoEvento.emergencia,
  TipoAlerta.excesoVelocidad: TipoEvento.excesovelocidad,
  TipoAlerta.fallaMecanica: TipoEvento.fallaMecanica,
  TipoAlerta.combustibleBajo: TipoEvento.paradaNoProgramada,
  TipoAlerta.perdidaGps: TipoEvento.otro,
};

class IncidenciaService {
  /// Registra una incidencia (alerta + evento) para un viaje en curso.
  Future<void> registrarIncidencia({
    required String idViaje,
    required String tipoAlerta,
    required String descripcion,
  }) async {
    final tipoEvento = tipoAlertaAEvento[tipoAlerta] ?? TipoEvento.otro;

    final response = await http.post(
      Uri.parse(ApiConstants.incidencias),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idViaje': idViaje,
        'tipoAlerta': tipoAlerta,
        'tipoEvento': tipoEvento,
        'descripcion': descripcion,
      }),
    );

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Error al registrar incidencia');
    }
  }

  /// Obtiene los catálogos de enums desde el backend.
  Future<Map<String, dynamic>> obtenerEnums() async {
    final response = await http.get(Uri.parse(ApiConstants.enums));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error al obtener catálogos');
  }

  /// Obtiene todas las alertas de un viaje.
  Future<List<dynamic>> obtenerAlertasPorViaje(String idViaje) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.alertas}/viaje/$idViaje'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Error al obtener alertas');
  }

  /// Obtiene las alertas pendientes (no resueltas) de un viaje.
  Future<List<dynamic>> obtenerAlertasPendientes(String idViaje) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.alertas}/viaje/$idViaje/pendientes'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Error al obtener alertas pendientes');
  }
}
