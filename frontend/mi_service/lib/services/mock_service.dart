import 'dart:async';
import '../models/conductor.dart';
import '../models/vehiculo.dart';
import '../models/viaje.dart';
import '../models/ubicacion.dart';
import '../models/alerta.dart';

class MockService {
  static final MockService _instance = MockService._internal();
  factory MockService() => _instance;
  MockService._internal();

  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.contains('admin')) {
      return {
        'id': 1,
        'nombre': 'Admin',
        'email': email,
        'rol': 'admin',
        'token': 'fake-jwt-token-admin'
      };
    } else {
      return {
        'id': 2,
        'nombre': 'Conductor',
        'email': email,
        'rol': 'conductor',
        'token': 'fake-jwt-token-driver'
      };
    }
  }

  Future<List<Conductor>> getConductores() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Conductor(usuarioId: 1, nombre: 'Luis Martínez', email: 'luis@test.com', licencia: 'B123', telefono: '600111222', sueldo: 1800, edad: 35, disponible: true),
      Conductor(usuarioId: 2, nombre: 'María Fernández', email: 'maria@test.com', licencia: 'B456', telefono: '600222333', sueldo: 1900, edad: 29, disponible: true),
    ];
  }

  Future<List<Vehiculo>> getVehiculos() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Vehiculo(id: 1, placa: 'ABC-123', marca: 'Mercedes', modelo: 'Sprinter', anio: 2020, capacidad: 20, kilometraje: 12500.5, estado: 'EN_RUTA'),
      Vehiculo(id: 2, placa: 'DEF-456', marca: 'Volkswagen', modelo: 'Crafter', anio: 2021, capacidad: 18, kilometraje: 8900.2, estado: 'DISPONIBLE'),
    ];
  }

  Future<List<Viaje>> getViajesEnCurso() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Viaje(id: 1, vehiculoId: 1, conductorId: 1, rutaId: 1, fechaHoraInicio: DateTime.now().subtract(const Duration(minutes: 30)), estado: 'EN_CURSO'),
    ];
  }

  Future<Map<String, dynamic>> crearViaje(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {'id': 3, ...data};
  }

  Future<void> iniciarViaje(int viajeId) async {}
  Future<void> finalizarViaje(int viajeId, {double? kmFinal}) async {}
  Future<void> enviarUbicacion(Ubicacion ubicacion) async {
    print('Ubicación enviada: $ubicacion');
  }

  Future<List<Alerta>> getAlertasPendientes(int viajeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Alerta(id: 1, viajeId: 1, tipo: 'DESVIACION_RUTA', timestamp: DateTime.now().subtract(const Duration(minutes: 5)), mensaje: 'Se desvió de la ruta', resuelta: false),
    ];
  }
}