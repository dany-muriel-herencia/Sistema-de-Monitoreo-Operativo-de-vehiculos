import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Widget reutilizable para mostrar mapas con trazado de rutas (Polylines).
/// Llama a OSRM automáticamente para dibujar la ruta siguiendo calles reales.
class RutaMapaWidget extends StatefulWidget {
  /// Los waypoints guardados (puntos clave del administrador)
  final List<LatLng> puntos;
  final bool seguirUbicacion;
  final LatLng? centroInicial;

  const RutaMapaWidget({
    super.key,
    required this.puntos,
    this.seguirUbicacion = false,
    this.centroInicial,
  });

  @override
  State<RutaMapaWidget> createState() => _RutaMapaWidgetState();
}

class _RutaMapaWidgetState extends State<RutaMapaWidget> {
  final MapController _mapController = MapController();

  /// Geometría OSRM calculada (la ruta real por calles)
  List<LatLng> _polilineaOsrm = [];
  bool _calculando = false;
  bool _calculado = false;

  @override
  void initState() {
    super.initState();
    if (widget.puntos.length >= 2) {
      _calcularRutaOsrm(widget.puntos);
    }
  }

  @override
  void didUpdateWidget(covariant RutaMapaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.seguirUbicacion && widget.puntos.isNotEmpty) {
      if (oldWidget.puntos.isEmpty || oldWidget.puntos.last != widget.puntos.last) {
        _mapController.move(widget.puntos.last, _mapController.camera.zoom);
      }
    }

    // Si los waypoints cambiaron, recalculamos la ruta OSRM
    if (widget.puntos.length >= 2 &&
        (oldWidget.puntos.length != widget.puntos.length ||
            widget.puntos != oldWidget.puntos)) {
      _calculado = false;
      _calcularRutaOsrm(widget.puntos);
    }
  }

  // ─── OSRM: ruta multi-segmento ─────────────────────────────────────────────

  List<LatLng> _decodificarPolyline6(String encoded) {
    final List<LatLng> result = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result0 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      lat += dlat;

      shift = 0;
      result0 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      lng += dlng;

      result.add(LatLng(lat / 1e6, lng / 1e6));
    }
    return result;
  }

  Future<void> _calcularRutaOsrm(List<LatLng> waypoints) async {
    if (_calculando) return;
    setState(() {
      _calculando = true;
      _polilineaOsrm = [];
    });

    try {
      // Construir la lista de coordenadas en formato OSRM: lon,lat;lon,lat;...
      // (OSRM acepta hasta ~25 waypoints en el servidor público)
      final coords = waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coords'
        '?overview=full&geometries=polyline6&steps=false',
      );

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok') {
          final geometry = data['routes'][0]['geometry'] as String;
          final puntos = _decodificarPolyline6(geometry);

          if (mounted) {
            setState(() {
              _polilineaOsrm = puntos;
              _calculando = false;
              _calculado = true;
            });
            return;
          }
        }
      }
    } catch (_) {
      // En caso de error, fallback a línea recta
    }

    // Fallback: usar los waypoints como línea recta
    if (mounted) {
      setState(() {
        _polilineaOsrm = List.from(waypoints);
        _calculando = false;
        _calculado = true;
      });
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final LatLng centro = widget.centroInicial ??
        (widget.puntos.isNotEmpty
            ? widget.puntos.first
            : const LatLng(-18.0146, -70.2536));

    final List<LatLng> lineaAMostrar =
        _polilineaOsrm.isNotEmpty ? _polilineaOsrm : widget.puntos;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centro,
              initialZoom: 13.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Capa de tiles OpenStreetMap HOT
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.monitoreo.flota',
              ),

              // Halo/sombra de la polilínea
              if (lineaAMostrar.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: lineaAMostrar,
                      color: Colors.white.withValues(alpha: 0.3),
                      strokeWidth: 9.0,
                    ),
                  ],
                ),

              // Polilínea principal
              if (lineaAMostrar.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: lineaAMostrar,
                      color: const Color(0xFF8E24ED),
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.0,
                    ),
                  ],
                ),

              // Marcadores de waypoints
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),

          // Indicador de carga mientras OSRM calcula
          if (_calculando)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF8E24ED),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Calculando ruta real...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Badge "Ruta OSRM" cuando está calculada
          if (_calculado && _polilineaOsrm.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E24ED).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alt_route, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Ruta real',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    if (widget.puntos.isEmpty) return [];

    return widget.puntos.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;

      final bool isFirst = index == 0;
      final bool isLast = index == widget.puntos.length - 1;

      if (isFirst || isLast) {
        return Marker(
          point: point,
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.location_on,
                color: isFirst ? Colors.green.shade600 : Colors.red.shade600,
                size: 46,
              ),
              Positioned(
                top: 6,
                child: Icon(
                  isFirst ? Icons.play_arrow : Icons.flag,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        );
      }

      return Marker(
        point: point,
        width: 24,
        height: 24,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF8E24ED),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
