import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/viaje_service.dart';
import '../../services/ruta_service.dart';
import '../../services/incidencia_service.dart';
import '../../services/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/viaje.dart';
import '../../models/ruta.dart';
import 'package:geolocator/geolocator.dart';
import 'driver_mapa_screen.dart';


class DriverHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const DriverHomeScreen({super.key, required this.user});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _viajeService = ViajeService();
  final _rutaService = RutaService();
  final _incidenciaService = IncidenciaService();
  bool _isLoading = true;
  bool _isActionLoading = false;
  Viaje? _activeViaje;
  Ruta? _rutaAsignada;
  StreamSubscription<Position>? _gpsStreamSubscription;


  @override
  void initState() {
    super.initState();
    _loadActiveTrip();
  }

  @override
  void dispose() {
    _gpsStreamSubscription?.cancel();
    super.dispose();
  }


  Future<void> _loadActiveTrip() async {
    setState(() => _isLoading = true);
    try {
      final viajes = await _viajeService.obtenerViajes();
      final userId = widget.user['id'].toString();
      
      Viaje? found;
      for (var v in viajes) {
        if (v.conductorId == userId && (v.estado == 'PLANIFICADO' || v.estado == 'EN_CURSO')) {
          found = v;
          break;
        }
      }

      // Cargar la ruta asignada al viaje
      Ruta? ruta;
      if (found != null && found.rutaId.isNotEmpty) {
        try {
          final rutas = await _rutaService.obtenerRutas();
          // Buscar la ruta que coincida con el idRuta del viaje
          try {
            ruta = rutas.firstWhere((r) => r.id == found!.rutaId);
          } catch (_) {
            ruta = null;
          }
        } catch (_) {}
      }

      setState(() {
        _activeViaje = found;
        _rutaAsignada = ruta;
        _isLoading = false;
      });

      if (_activeViaje?.estado == 'EN_CURSO') {
        _startRealGpsTracking();
      } else {
        _gpsStreamSubscription?.cancel();
      }

    } catch (e) {
      setState(() {
        _activeViaje = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _startRealGpsTracking() async {
    _gpsStreamSubscription?.cancel();

    // 1. Verificar si el servicio de ubicación está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('El GPS está desactivado. Por favor actívalo.', Colors.orange);
      return;
    }

    // 2. Verificar/Solicitar permisos
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Permiso de GPS denegado.', Colors.red);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Permisos de GPS denegados permanentemente.', Colors.red);
      return;
    }

    // 3. Suscribirse al flujo de posiciones
    _gpsStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Notificar cada 10 metros
      ),
    ).listen((Position position) async {
      if (_activeViaje == null || _activeViaje!.estado != 'EN_CURSO') {
        _gpsStreamSubscription?.cancel();
        return;
      }
      
      try {
        await http.post(
          Uri.parse(ApiConstants.ubicaciones),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idviaje': _activeViaje!.id,
            'idVehiculo': _activeViaje!.vehiculoId,
            'latitud': position.latitude,
            'longitud': position.longitude,
            'velocidad': position.speed * 3.6 // Convertir m/s a km/h
          }),
        );
        print('GPS REAL: Ubicación enviada (${position.latitude}, ${position.longitude})');
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

  Future<void> _reportarIncidencia() async {
    if (_activeViaje == null) return;

    String? tipoSeleccionado;
    final descController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Reportar Incidencia'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tipo de incidencia:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...TipoAlerta.todos.map((tipo) => RadioListTile<String>(
                    dense: true,
                    value: tipo,
                    groupValue: tipoSeleccionado,
                    title: Text(TipoAlerta.label(tipo)),
                    onChanged: (v) => setDlgState(() => tipoSeleccionado = v),
                  )),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              onPressed: tipoSeleccionado == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );

    if (confirmar == true && tipoSeleccionado != null) {
      try {
        await _incidenciaService.registrarIncidencia(
          idViaje: _activeViaje!.id,
          tipoAlerta: tipoSeleccionado!,
          descripcion: descController.text.trim().isNotEmpty
              ? descController.text.trim()
              : TipoAlerta.label(tipoSeleccionado!),
        );
        _showSnackBar('Incidencia reportada ✅', Colors.orange);
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
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
                                _buildDetailItem(Icons.map, 'Ruta Asignada', _rutaAsignada?.nombre ?? 'Sin ruta'),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DriverMapaScreen(
                                            puntosRuta: _rutaAsignada?.puntos ?? [],
                                            nombreRuta: _rutaAsignada?.nombre ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.map),
                                    label: const Text('Ver mi ubicación en el Mapa'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue.shade700,
                                      side: BorderSide(color: Colors.blue.shade700),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
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
                                    Expanded(child: Text('Monitoreo GPS real activo. Enviando ubicación automáticamente.', style: TextStyle(color: Colors.blue))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Botón Reportar Incidencia
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _reportarIncidencia(),
                                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                  label: const Text('Reportar Incidencia', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.orange, width: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
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
