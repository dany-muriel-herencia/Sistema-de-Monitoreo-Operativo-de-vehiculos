import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/viaje_service.dart';
import '../../services/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/viaje.dart';

class DriverHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DriverHomeScreen({super.key, required this.user});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _viajeService = ViajeService();
  bool _isLoading = true;
  bool _isActionLoading = false;
  Viaje? _activeViaje;
  Timer? _gpsTimer;

  @override
  void initState() {
    super.initState();
    _loadActiveTrip();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveTrip() async {
    setState(() => _isLoading = true);
    try {
      final viajes = await _viajeService.obtenerViajes();
      final userId = widget.user['id'].toString();
      
      setState(() {
        _activeViaje = null;
        for (var v in viajes) {
          if (v.conductorId == userId && (v.estado == 'PLANIFICADO' || v.estado == 'EN_CURSO')) {
            _activeViaje = v;
            break;
          }
        }
        _isLoading = false;
      });

      if (_activeViaje?.estado == 'EN_CURSO') {
        _startGpsSimulation();
      } else {
        _gpsTimer?.cancel();
      }
    } catch (e) {
      setState(() {
        _activeViaje = null;
        _isLoading = false;
      });
    }
  }

  void _startGpsSimulation() {
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_activeViaje == null || _activeViaje!.estado != 'EN_CURSO') {
        timer.cancel();
        return;
      }
      
      try {
        // Enviar ubicación de prueba (Bogotá aprox)
        await http.post(
          Uri.parse(ApiConstants.ubicaciones),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idviaje': _activeViaje!.id,
            'idVehiculo': _activeViaje!.vehiculoId,
            'latitud': 4.6097 + (timer.tick * 0.0001),
            'longitud': -74.0817 + (timer.tick * 0.0001),
            'velocidad': 45.0
          }),
        );
        print('GPS: Ubicación enviada para viaje ${_activeViaje!.id}');
      } catch (e) {
        print('GPS Error: $e');
      }
    });
  }

  Future<void> _iniciar() async {
    setState(() => _isActionLoading = true);
    try {
      await _viajeService.iniciarViaje(_activeViaje!.id, widget.user['id'].toString());
      await _loadActiveTrip();
      _showSnackBar('¡Buen viaje!', Colors.green);
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  Future<void> _finalizar() async {
    final TextEditingController kmController = TextEditingController();
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Viaje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Por favor, ingresa el kilometraje final del vehículo:'),
            const SizedBox(height: 16),
            TextField(
              controller: kmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilometraje Final',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finalizar')),
        ],
      ),
    );

    if (confirm == true) {
      if (kmController.text.isEmpty) {
        _showSnackBar('El kilometraje es obligatorio', Colors.orange);
        return;
      }

      setState(() => _isActionLoading = true);
      try {
        await _viajeService.finalizarViaje(
          _activeViaje!.id, 
          widget.user['id'].toString(),
          _activeViaje!.vehiculoId,
          int.parse(kmController.text)
        );
        await _loadActiveTrip();
        _showSnackBar('Viaje finalizado con éxito', Colors.blue);
      } catch (e) {
        _showSnackBar(e.toString(), Colors.red);
      } finally {
        setState(() => _isActionLoading = false);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${widget.user['nombre']}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActiveTrip,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _activeViaje == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No tienes viajes asignados.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton(onPressed: _loadActiveTrip, child: const Text('Actualizar')),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView( // Usar ListView para que el RefreshIndicator funcione bien
                      children: [
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: _activeViaje!.estado == 'EN_CURSO' ? Colors.green : Colors.orange, 
                                  width: 8
                                )
                              )
                            ),
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('DETALLES DEL VIAJE', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _activeViaje!.estado == 'EN_CURSO' ? Colors.green.shade50 : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4)
                                      ),
                                      child: Text(
                                        _activeViaje!.estado,
                                        style: TextStyle(
                                          color: _activeViaje!.estado == 'EN_CURSO' ? Colors.green : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildDetailItem(Icons.tag, 'ID de Viaje', _activeViaje!.id),
                                _buildDetailItem(Icons.directions_car, 'Placa Vehículo', _activeViaje!.vehiculoId),
                                _buildDetailItem(Icons.map, 'ID de Ruta', 'Ruta #1'), // TODO: Mejorar esto
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_isActionLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_activeViaje!.estado == 'PLANIFICADO')
                          ElevatedButton.icon(
                            onPressed: _iniciar,
                            icon: const Icon(Icons.play_circle_fill, size: 32),
                            label: const Text('COMENZAR VIAJE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        else if (_activeViaje!.estado == 'EN_CURSO')
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.gps_fixed, color: Colors.blue),
                                    SizedBox(width: 12),
                                    Expanded(child: Text('Simulación de GPS activa. Enviando ubicación cada 10s.', style: TextStyle(color: Colors.blue))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _finalizar,
                                icon: const Icon(Icons.check_circle, size: 32),
                                label: const Text('FINALIZAR VIAJE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
