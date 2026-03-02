import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class AuthService {
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      print('Intentando login en: ${ApiConstants.login}');
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Respuesta recibida: ${response.statusCode}');
      print('Cuerpo: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al iniciar sesión: ${response.body}');
      }
    } catch (e) {
      print('AuthService Error: $e');
      rethrow;
    }
  }
}
