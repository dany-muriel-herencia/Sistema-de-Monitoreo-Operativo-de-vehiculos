import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/viaje_service.dart';

class MonitoreoMapaScreen extends StatefulWidget {
  final List<dynamic> monitoreoData;

  const MonitoreoMapaScreen({super.key, required this.monitoreoData});

  @override
  State<MonitoreoMapaScreen> createState() => _MonitoreoMapaScreenState();
}

class _MonitoreoMapaScreenState extends State<MonitoreoMapaScreen> {
  final MapController _mapController = MapController();
  final ViajeService _viajeService = ViajeService();

  bool _isSatellite = false;
  bool _siguiendoUbicacion = false;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  List<dynamic> _liveData = [];
  Timer? _refreshTimer;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _liveData = List.from(widget.monitoreoData);
    _lastUpdate = DateTime.now();
    // Actualizar cada 4 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchLive());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscarDireccion(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
      final response = await http.get(url, headers: {'User-Agent': 'FlutterFlotaApp/1.0'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final point = LatLng(lat, lon);
          
          setState(() => _siguiendoUbicacion = false);
          _mapController.move(point, 16.0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ubicación: ${data[0]['display_name']}'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró la dirección.'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error en la búsqueda.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchLive() async {
    try {
      final data = await _viajeService.obtenerMonitoreo();
      if (!mounted) return;
      setState(() {
        _liveData = data;
        _lastUpdate = DateTime.now();
      });

      // Si está en modo seguimiento y hay datos, mover el mapa al primer vehículo
      if (_siguiendoUbicacion && data.isNotEmpty && data[0]['ultimaUbicacion'] != null) {
        final lat = double.parse(data[0]['ultimaUbicacion']['latitud'].toString());
        final lng = double.parse(data[0]['ultimaUbicacion']['longitud'].toString());
        _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final markerData = _liveData.where((m) => m['ultimaUbicacion'] != null).toList();
    final ahora = _lastUpdate;
    final timeStr = ahora != null
        ? '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}:${ahora.second.toString().padLeft(2, '0')}'
        : '--';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monitoreo de Flota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                Text('${markerData.length} activos • Actualizado $timeStr',
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSatellite ? Icons.map : Icons.satellite_alt),
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
            tooltip: 'Cambiar Tipo de Mapa',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLive,
            tooltip: 'Actualizar ahora',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: markerData.isNotEmpty
                  ? LatLng(
                      double.parse(markerData[0]['ultimaUbicacion']['latitud'].toString()),
                      double.parse(markerData[0]['ultimaUbicacion']['longitud'].toString()),
                    )
                  : const LatLng(-12.046374, -77.042793),
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapEvent: (event) {
                // Si el usuario mueve el mapa manualmente con el mouse/dedo, desactiva el seguimiento automático
                if (event is MapEventMove && event.source != MapEventSource.mapController) {
                  if (_siguiendoUbicacion) {
                    setState(() => _siguiendoUbicacion = false);
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.flota.monitoreo',
              ),
              MarkerLayer(
                markers: markerData.map((m) {
                  final lat = double.parse(m['ultimaUbicacion']['latitud'].toString());
                  final lng = double.parse(m['ultimaUbicacion']['longitud'].toString());
                  final placa = m['placa'];
                  final velocidad = m['ultimaUbicacion']['velocidad'] ?? 0;
                  
                  Color markerColor = Colors.green;
                  if (velocidad > 80) markerColor = Colors.red;
                  else if (velocidad > 40) markerColor = Colors.orange;

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 100,
                    height: 100,
                    child: GestureDetector(
                      onTap: () => _showVehicleDetails(context, m),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: markerColor, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Text(
                              '$placa • ${(velocidad as num).toStringAsFixed(0)} km/h',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(Icons.local_shipping, color: markerColor, size: 36),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Barra de Búsqueda de Direcciones
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar calle o vivienda...',
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: Colors.blue),
                    suffixIcon: _isSearching 
                      ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                      : IconButton(
                          icon: const Icon(Icons.clear), 
                          onPressed: () => _searchController.clear()
                        ),
                  ),
                  onSubmitted: _buscarDireccion,
                ),
              ),
            ),
          ),

          // Mensaje si no hay vehículos activos
          if (markerData.isEmpty)
            Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No hay vehículos con ubicación activa.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      const Text('El mapa se actualizará automáticamente cada 4 seg.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),

          // Botón centrar
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                  child: const Icon(Icons.add, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                  child: const Icon(Icons.remove, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'follow_btn',
                  mini: true,
                  backgroundColor: _siguiendoUbicacion ? Colors.blue.shade700 : Colors.white,
                  onPressed: () {
                    setState(() => _siguiendoUbicacion = !_siguiendoUbicacion);
                    if (_siguiendoUbicacion && markerData.isNotEmpty) {
                      _mapController.move(
                        LatLng(
                          double.parse(markerData[0]['ultimaUbicacion']['latitud'].toString()),
                          double.parse(markerData[0]['ultimaUbicacion']['longitud'].toString()),
                        ),
                        15,
                      );
                    }
                  },
                  tooltip: 'Seguimiento Automático',
                  child: Icon(
                    _siguiendoUbicacion ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: _siguiendoUbicacion ? Colors.white : Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'center_btn',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (markerData.isNotEmpty) {
                      _mapController.move(
                        LatLng(
                          double.parse(markerData[0]['ultimaUbicacion']['latitud'].toString()),
                          double.parse(markerData[0]['ultimaUbicacion']['longitud'].toString()),
                        ),
                        15,
                      );
                    }
                  },
                  tooltip: 'Centrar en el primer vehículo',
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ],
            ),
          ),

          // Badge LIVE
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.white),
                  SizedBox(width: 4),
                  Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVehicleDetails(BuildContext context, dynamic data) {
    final lat = data['ultimaUbicacion']['latitud'];
    final lng = data['ultimaUbicacion']['longitud'];
    final velocidad = data['ultimaUbicacion']['velocidad'] ?? 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehículo: ${data['placa']}', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text('Estado: ${data['estado']}', 
                        style: TextStyle(color: data['estado'] == 'EN_CURSO' ? Colors.green : Colors.grey)),
                    ],
                  ),
                  const Icon(Icons.local_shipping, size: 40, color: Colors.blue),
                ],
              ),
              const Divider(height: 32),
              _buildInfoRow(Icons.person, 'Conductor', data['conductor'] ?? 'Sin asignar'),
              _buildInfoRow(Icons.route, 'Ruta', data['ruta'] ?? 'Sin ruta'),
              _buildInfoRow(Icons.near_me, 'Siguiente Parada', data['proximaParada'] ?? 'Llegando...'),
              _buildInfoRow(Icons.speed, 'Velocidad', '${(velocidad as num).toStringAsFixed(1)} km/h'),
              _buildInfoRow(Icons.location_on, 'Coordenadas', '$lat, $lng'),
              _buildInfoRow(Icons.access_time, 'Último reporte', data['ultimaUbicacion']['timestamp']?.toString().split('T')[0] ?? 'N/A'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CERRAR'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
