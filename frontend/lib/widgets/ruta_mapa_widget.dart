import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget reutilizable para mostrar mapas con trazado de rutas (Polylines)
/// y marcadores de inicio/fin.
class RutaMapaWidget extends StatefulWidget {
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

  @override
  void didUpdateWidget(covariant RutaMapaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si los puntos cambian y el seguimiento está activo, movemos el mapa
    if (widget.seguirUbicacion && widget.puntos.isNotEmpty) {
      if (oldWidget.puntos.isEmpty || 
          oldWidget.puntos.last != widget.puntos.last) {
        _mapController.move(widget.puntos.last, _mapController.camera.zoom);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determinar el centro del mapa
    final LatLng centro = widget.centroInicial ?? 
        (widget.puntos.isNotEmpty ? widget.puntos.first : const LatLng(-12.0463, -77.0427));

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: centro,
          initialZoom: 14.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          // Capa de mapa real (OpenStreetMap Hot Style)
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.monitoreo.flota',
          ),

          // Trazado de la ruta (Línea)
          if (widget.puntos.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: widget.puntos,
                  color: const Color(0xFF8E24ED), // Púrpura corporativo
                  strokeWidth: 5.0,
                  isDotted: false,
                  borderColor: Colors.white,
                  borderStrokeWidth: 1.0,
                ),
              ],
            ),

          // Marcadores de paradas, inicio y fin
          MarkerLayer(
            markers: _buildMarkers(),
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

      // Estilo visual para marcadores principales o intermedios
      if (isFirst || isLast) {
        return Marker(
          point: point,
          width: 45,
          height: 45,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.location_on,
                color: isFirst ? Colors.green : Colors.red,
                size: 45,
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

      // Marcadores intermedios simples
      return Marker(
        point: point,
        width: 20,
        height: 20,
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
              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }).toList();
  }
}
