import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehiculo.dart';
import 'api_constants.dart';

class VehiculoService {
  Future<List<Vehiculo>> obtenerVehiculos() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.vehiculos));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Vehiculo.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener vehículos: ${response.body}');
      }
    } catch (e) {
      print('VehiculoService.obtenerVehiculos Error: $e');
      rethrow;
    }
  }

  Future<void> crearVehiculo(Map<String, dynamic> datos) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.vehiculos),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(datos),
      );

      if (response.statusCode != 201) {
        throw Exception('Error al crear vehículo: ${response.body}');
      }
    } catch (e) {
      print('VehiculoService.crearVehiculo Error: $e');
      rethrow;
    }
  }

  Future<void> eliminarVehiculo(String placa) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.vehiculos}/$placa'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar vehículo: ${response.body}');
      }
    } catch (e) {
      print('VehiculoService.eliminarVehiculo Error: $e');
      rethrow;
    }
  }
}
