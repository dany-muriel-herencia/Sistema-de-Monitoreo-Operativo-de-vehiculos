import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conductor.dart';
import 'api_constants.dart';

class ConductorService {
  Future<List<Conductor>> obtenerConductores() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.conductores));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Conductor.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener conductores: ${response.body}');
      }
    } catch (e) {
      print('ConductorService.obtenerConductores Error: $e');
      rethrow;
    }
  }

  Future<void> crearConductor(Map<String, dynamic> datos) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.conductores),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );

      if (response.statusCode != 201) {
        throw Exception('Error al crear conductor: ${response.body}');
      }
    } catch (e) {
      print('ConductorService.crearConductor Error: $e');
      rethrow;
    }
  }

  Future<void> eliminarConductor(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.conductores}/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar conductor: ${response.body}');
      }
    } catch (e) {
      print('ConductorService.eliminarConductor Error: $e');
      rethrow;
    }
  }
}
