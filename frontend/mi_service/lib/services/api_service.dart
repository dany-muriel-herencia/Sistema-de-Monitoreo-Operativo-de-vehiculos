import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  final Dio dio = Dio();

  ApiService._internal() {
    dio.options.baseUrl = 'http://localhost:3000/api';
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  // --- HELPER PARA LIMPIAR DATOS DEL BACKEND ---
  dynamic _processData(dynamic data) {
    if (data is List) return data.map((e) => _processData(e)).toList();
    if (data is Map) {
      final Map<String, dynamic> clean = {};
      data.forEach((key, value) {
        // Si el backend manda IDs como Strings, los normalizamos aquí si fuera necesario
        // Pero por ahora dejamos que el modelo haga el tryParse final por seguridad.
        clean[key] = value;
      });
      return clean;
    }
    return data;
  }

  Future<dynamic> get(String path) async {
    try {
      final response = await dio.get(path);
      return _processData(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path, dynamic data) async {
    try {
      final response = await dio.post(path, data: data);
      return _processData(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await dio.patch(path, data: data);
      return _processData(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final msg = error.response?.data['error'] ?? error.response?.data['mensaje'];
        return 'Error ${error.response?.statusCode}: ${msg ?? error.response?.statusMessage}';
      }
      return 'Error de conexión: ${error.message}';
    }
    return 'Error inesperado';
  }

  // --- HELPERS DE CONVENIENCIA ---
  Future<void> enviarUbicacion(dynamic ubicacion) async {
    await post('/ubicaciones', ubicacion is Map ? ubicacion : ubicacion.toJson());
  }
}
