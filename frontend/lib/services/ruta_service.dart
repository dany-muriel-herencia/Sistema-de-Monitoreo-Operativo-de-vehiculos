import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ruta.dart';
import 'api_constants.dart';

class RutaService {
  Future<List<Ruta>> obtenerRutas() async {
    final response = await http.get(Uri.parse(ApiConstants.rutas));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Ruta.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar rutas: ${response.statusCode}');
    }
  }

  Future<void> crearRuta(Map<String, dynamic> rutaData) async {
    final response = await http.post(
      Uri.parse(ApiConstants.rutas),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(rutaData),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear ruta: ${response.body}');
    }
  }

  Future<void> eliminarRuta(String id) async {
    final response = await http.delete(Uri.parse('${ApiConstants.rutas}/$id'));
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar ruta');
    }
  }

  Future<void> actualizarRuta(String id, Map<String, dynamic> rutaData) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.rutas}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(rutaData),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar ruta: ${response.body}');
    }
  }
}

