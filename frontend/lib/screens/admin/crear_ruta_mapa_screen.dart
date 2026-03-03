import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/ruta_service.dart';
import '../../models/ruta.dart';

/// Pantalla dedicada para crear o editar una ruta dibujando puntos en el mapa.
class CrearRutaMapaScreen extends StatefulWidget {
  final Ruta? rutaExistente;
  const CrearRutaMapaScreen({super.key, this.rutaExistente});

  @override
  State<CrearRutaMapaScreen> createState() => _CrearRutaMapaScreenState();
}

class _CrearRutaMapaScreenState extends State<CrearRutaMapaScreen> {
  final MapController _mapController = MapController();
  final RutaService _rutaService = RutaService();

  final _nombreController = TextEditingController();
  final List<LatLng> _puntos = [];
  bool _isSatellite = false;
  bool _isLoading = false;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  // Perú como centro por defecto
  static const LatLng _defaultCenter = LatLng(-12.046374, -77.042793);

  @override
  void initState() {
    super.initState();
    if (widget.rutaExistente != null) {
      _nombreController.text = widget.rutaExistente!.nombre;
      _puntos.addAll(
        widget.rutaExistente!.puntos
            .map((p) => LatLng(p.latitud, p.longitud))
            .toList(),
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
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
          
          _mapController.move(point, 16.0);
          _showSnack('Ubicación encontrada: ${data[0]['display_name']}', Colors.green);
        } else {
          _showSnack('No se encontró la dirección.', Colors.orange);
        }
      }
    } catch (e) {
      _showSnack('Error en la búsqueda.', Colors.red);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  /// Calcula la distancia total entre puntos consecutivos en km
  double _calcularDistanciaKm() {
    if (_puntos.length < 2) return 0;
    double total = 0;
    const distCalc = Distance();
    for (int i = 0; i < _puntos.length - 1; i++) {
      total += distCalc.as(LengthUnit.Kilometer, _puntos[i], _puntos[i + 1]);
    }
    return total;
  }

  /// Estimación: 40 km/h promedio en ciudad
  int _estimarDuracionMinutos(double distKm) {
    return (distKm / 40.0 * 60).round();
  }

  void _onMapTap(TapPosition tapPos, LatLng point) {
    setState(() => _puntos.add(point));
  }

  void _removePoint(int index) {
    setState(() => _puntos.removeAt(index));
  }

  void _clearAll() {
    setState(() => _puntos.clear());
  }

  Future<void> _guardarRuta() async {
    if (_nombreController.text.trim().isEmpty) {
      _showSnack('Ingresa un nombre para la ruta', Colors.orange);
      return;
    }
    if (_puntos.length < 2) {
      _showSnack('Agrega al menos 2 puntos en el mapa', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final distancia = _calcularDistanciaKm();
    final duracion = _estimarDuracionMinutos(distancia);

    final datos = {
      'nombre': _nombreController.text.trim(),
      'distanciaTotal': double.parse(distancia.toStringAsFixed(2)),
      'duracionEstimadaMinutos': duracion,
      'puntos': _puntos.asMap().entries.map((e) => {
        'lat': e.value.latitude,
        'lng': e.value.longitude,
        'orden': e.key + 1,
      }).toList(),
    };

    try {
      if (widget.rutaExistente != null) {
        await _rutaService.actualizarRuta(widget.rutaExistente!.id, datos);
        _showSnack('Ruta actualizada con éxito ✅', Colors.green);
      } else {
        await _rutaService.crearRuta(datos);
        _showSnack('Ruta guardada con éxito ✅', Colors.green);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnack('Error al guardar: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distancia = _calcularDistanciaKm();
    final duracion = _estimarDuracionMinutos(distancia);
    final center = _puntos.isNotEmpty ? _puntos.last : _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.rutaExistente != null ? 'Editar Ruta en Mapa' : 'Crear Ruta en Mapa',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSatellite ? Icons.map : Icons.satellite_alt),
            tooltip: 'Cambiar tipo de mapa',
            onPressed: () => setState(() => _isSatellite = !_isSatellite),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Limpiar todos los puntos',
            onPressed: _puntos.isEmpty ? null : _clearAll,
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── MAPA PRINCIPAL ──────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.flota.monitoreo',
              ),
              // Línea que conecta los puntos
              if (_puntos.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _puntos,
                      color: Colors.blue.shade700,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              // Marcadores de cada punto
              MarkerLayer(
                markers: _puntos.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final isFirst = i == 0;
                  final isLast = i == _puntos.length - 1 && _puntos.length > 1;

                  Color markerBg = Colors.blue.shade700;
                  if (isFirst) markerBg = Colors.green;
                  if (isLast) markerBg = Colors.red;

                  return Marker(
                    point: p,
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onLongPress: () => _removePoint(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: markerBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 4)
                          ],
                        ),
                        child: Center(
                          child: isFirst
                              ? const Icon(Icons.flag, color: Colors.white, size: 20)
                              : isLast
                                  ? const Icon(Icons.sports_score, color: Colors.white, size: 20)
                                  : Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── PANEL SUPERIOR: nombre + estadísticas ───────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                // Barra de Búsqueda de Direcciones
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar calle, ciudad o vivienda...',
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: Colors.blue),
                        suffixIcon: _isSearching 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.clear), 
                              onPressed: () => _searchController.clear()
                            ),
                      ),
                      onSubmitted: _buscarDireccion,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            hintText: 'Nombre de la ruta...',
                            prefixIcon: const Icon(Icons.route, color: Colors.blue),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                          ),
                        ),
                        if (_puntos.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _statChip(Icons.location_on, '${_puntos.length} puntos', Colors.blue),
                              _statChip(Icons.straighten, '${distancia.toStringAsFixed(2)} km', Colors.orange),
                              _statChip(Icons.schedule, '$duracion min', Colors.green),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                  child: const Icon(Icons.add, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                  child: const Icon(Icons.remove, color: Colors.blue),
                ),
              ],
            ),
          ),

          // ── LEYENDA ─────────────────────────────────────────────
          if (_puntos.isNotEmpty)
            Positioned(
              left: 12,
              bottom: 90,
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _legendItem(Colors.green, 'Inicio'),
                      const SizedBox(height: 4),
                      _legendItem(Colors.blue.shade700, 'Parada'),
                      const SizedBox(height: 4),
                      _legendItem(Colors.red, 'Fin'),
                      const SizedBox(height: 4),
                      const Text('Mantén presionado\npara eliminar',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),

          // ── PANEL INSTRUCCIONES (solo si no hay puntos) ─────────
          if (_puntos.isEmpty)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Card(
                color: Colors.blue.shade900.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Toca el mapa para agregar puntos de la ruta.\nMantén presionado un punto para eliminarlo.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── BOTÓN GUARDAR ───────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _guardarRuta,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_alt),
              label: Text(
                widget.rutaExistente != null ? 'ACTUALIZAR RUTA' : 'GUARDAR RUTA',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
