import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/conductor.dart';
import '../models/vehiculo.dart';
import '../models/ruta.dart';
import '../services/conductor_service.dart';
import '../services/vehiculo_service.dart';
import '../services/viaje_service.dart';
import '../services/ruta_service.dart';
import '../models/viaje.dart' as model;

class AsignarVehiculoDialog extends StatefulWidget {
  final model.Viaje? viaje;
  const AsignarVehiculoDialog({super.key, this.viaje});

  @override
  State<AsignarVehiculoDialog> createState() => _AsignarVehiculoDialogState();
}

class _AsignarVehiculoDialogState extends State<AsignarVehiculoDialog> {
  final _viajeService = ViajeService();
  final _conductorService = ConductorService();
  final _vehiculoService = VehiculoService();
  final _rutaService = RutaService();

  Conductor? _selectedConductor;
  Vehiculo? _selectedVehiculo;
  Ruta? _selectedRuta;
  
  List<Conductor> _conductores = [];
  List<Vehiculo> _vehiculos = [];
  List<Ruta> _rutas = [];
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final results = await Future.wait([
        _conductorService.obtenerConductores(),
        _vehiculoService.obtenerVehiculos(),
        _rutaService.obtenerRutas(),
      ]);
      
      setState(() {
        _conductores = results[0] as List<Conductor>;
        _vehiculos = results[1] as List<Vehiculo>;
        _rutas = results[2] as List<Ruta>;

        // Filtrar conductores y vehículos disponibles (o el actual si editamos)
        _conductores = _conductores.where((c) => c.disponible || (widget.viaje != null && c.id == widget.viaje!.conductorId)).toList();
        _vehiculos = _vehiculos.where((v) => v.estado.toUpperCase() == 'DISPONIBLE' || (widget.viaje != null && v.placa == widget.viaje!.vehiculoId)).toList();
        
        if (widget.viaje != null) {
          _selectedConductor = _conductores.where((c) => c.id == widget.viaje!.conductorId).firstOrNull;
          _selectedVehiculo = _vehiculos.where((v) => v.placa == widget.viaje!.vehiculoId).firstOrNull;
          _selectedRuta = _rutas.where((r) => r.id == widget.viaje!.rutaId).firstOrNull;
        }

        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _submit() async {
    if (_selectedConductor == null || _selectedVehiculo == null || _selectedRuta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (widget.viaje != null) {
        // Editar asignación (actualmente solo permite cambiar conductor/vehículo según código previo, 
        // pero podemos pasar la ruta también si fuera necesario, aunque el backend suele pedir solo conductor y placa en este endpoint específico)
        await _viajeService.actualizarAsignacion(
          widget.viaje!.id, 
          _selectedConductor!.id, 
          _selectedVehiculo!.placa
        );
      } else {
        // Nuevo Viaje (Planificar)
        await _viajeService.planificarViaje({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'idConductor': _selectedConductor!.id,
          'placa': _selectedVehiculo!.placa,
          'idRuta': _selectedRuta!.id,
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.viaje != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Asignación' : 'Planificar Nuevo Viaje'),
      content: _isLoadingData 
        ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
        : SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Conductor>(
                  value: _selectedConductor,
                  decoration: const InputDecoration(labelText: 'Conductor', prefixIcon: Icon(Icons.person)),
                  items: _conductores.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.nombre),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedConductor = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Vehiculo>(
                  value: _selectedVehiculo,
                  decoration: const InputDecoration(labelText: 'Vehículo', prefixIcon: Icon(Icons.local_shipping)),
                  items: _vehiculos.map((v) => DropdownMenuItem(
                    value: v,
                    child: Text('${v.marca} - ${v.placa}'),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedVehiculo = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Ruta>(
                  value: _selectedRuta,
                  decoration: const InputDecoration(labelText: 'Ruta de Transporte', prefixIcon: Icon(Icons.route)),
                  items: _rutas.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.nombre),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedRuta = v),
                ),
                if (_selectedRuta != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text('Tiempo Estimado (ETA): ${_selectedRuta!.duracionEstimadaMinutos} min', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.straighten, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text('Distancia total: ${_selectedRuta!.distanciaTotal} km', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        key: ValueKey(_selectedRuta!.id),
                        options: MapOptions(
                          initialCenter: _selectedRuta!.puntos.isNotEmpty 
                            ? LatLng(_selectedRuta!.puntos.first.latitud, _selectedRuta!.puntos.first.longitud) 
                            : const LatLng(-18.0146, -70.2536),
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                            userAgentPackageName: 'com.flota.monitoreo',
                          ),
                          if (_selectedRuta!.puntos.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: (_selectedRuta!.puntos.toList()..sort((a,b) => a.orden.compareTo(b.orden))).map((p) => LatLng(p.latitud, p.longitud)).toList(),
                                  color: const Color(0xFF8E24ED),
                                  strokeWidth: 4.0,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: _selectedRuta!.puntos.map((p) => Marker(
                              point: LatLng(p.latitud, p.longitud),
                              width: 24,
                              height: 24,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(p.orden.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8E24ED),
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting || _selectedConductor == null || _selectedVehiculo == null || _selectedRuta == null
            ? null 
            : _submit,
          child: _isSubmitting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : Text(isEditing ? 'Guardar Cambios' : 'Planificar Viaje'),
        ),
      ],
    );
  }
}

