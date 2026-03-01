import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ubicacion.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  Dio dio = Dio();

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
      dio.interceptors.add(LogInterceptor(responseBody: true));
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getConductores() async {
    try {
      final response = await dio.get('/conductores');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getVehiculos() async {
    try {
      final response = await dio.get('/vehiculos');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getViajesEnCurso() async {
    try {
      final response = await dio.get('/viajes/en-curso');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> crearViaje(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/viajes', data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> iniciarViaje(int viajeId) async {
    await dio.patch('/viajes/$viajeId/iniciar');
  }

  Future<void> finalizarViaje(int viajeId, {double? kmFinal}) async {
    await dio.patch('/viajes/$viajeId/finalizar', data: {'km_final': kmFinal});
  }

  Future<void> enviarUbicacion(Ubicacion ubicacion) async {
    await dio.post('/ubicaciones', data: ubicacion.toJson());
  }

  Future<List<dynamic>> getAlertasPendientes(int viajeId) async {
    try {
      final response = await dio.get('/alertas/viaje/$viajeId/pendientes');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        return 'Error ${error.response?.statusCode}: ${error.response?.data['message'] ?? error.response?.statusMessage}';
      } else {
        return 'Error de conexión: ${error.message}';
      }
    }
    return 'Error inesperado';
  }
}