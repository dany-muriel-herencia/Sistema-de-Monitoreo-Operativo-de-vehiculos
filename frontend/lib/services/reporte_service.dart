import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class ReporteService {
  Future<Map<String, dynamic>> obtenerResumenGeneral() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.reportes}/resumen'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener reportes: ${response.body}');
      }
    } catch (e) {
      print('ReporteService.obtenerResumenGeneral Error: $e');
      rethrow;
    }
  }

  // En una app real de escritorio o móvil usaríamos librerías de guardado.
  // En Web podemos simplemente retornar el URL del endpoint para que el navegador lo descargue.
  String getExportUrl() {
    return '${ApiConstants.reportes}/exportar';
  }
}
