import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/viaje.dart';
import 'api_constants.dart';

class ViajeService {
  Future<List<Viaje>> obtenerViajes() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.viajes));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Viaje.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener viajes: ${response.body}');
      }
    } catch (e) {
      print('ViajeService.obtenerViajes Error: $e');
      rethrow;
    }
  }

  Future<void> planificarViaje(Map<String, dynamic> datos) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.viajes),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );

      if (response.statusCode != 201) {
        throw Exception('Error al planificar viaje: ${response.body}');
      }
    } catch (e) {
      print('ViajeService.planificarViaje Error: $e');
      rethrow;
    }
  }

  Future<void> iniciarViaje(String idViaje, String idConductor) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.viajes}/$idViaje/iniciar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idConductor': idConductor}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al iniciar viaje: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> finalizarViaje(String idViaje, String idConductor, String placa, int kmFinales) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.viajes}/$idViaje/finalizar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idConductor': idConductor,
          'placa': placa,
          'kmFinales': kmFinales,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al finalizar viaje: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> obtenerMonitoreo() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/monitoreo'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener datos de monitoreo: ${response.body}');
      }
    } catch (e) {
      print('ViajeService.obtenerMonitoreo Error: $e');
      rethrow;
    }
  }

  Future<void> actualizarAsignacion(String idViaje, String idConductor, String idVehiculo) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/viajes/$idViaje'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idConductor': idConductor,
          'idVehiculo': idVehiculo,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar asignación: ${response.body}');
      }
    } catch (e) {
      print('ViajeService.actualizarAsignacion Error: $e');
      rethrow;
    }
  }
}
