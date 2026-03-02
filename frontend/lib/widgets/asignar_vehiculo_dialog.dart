import 'package:flutter/material.dart';
import '../models/conductor.dart';
import '../models/vehiculo.dart';
import '../services/conductor_service.dart';
import '../services/vehiculo_service.dart';
import '../services/viaje_service.dart';

class AsignarVehiculoDialog extends StatefulWidget {
  const AsignarVehiculoDialog({super.key});

  @override
  State<AsignarVehiculoDialog> createState() => _AsignarVehiculoDialogState();
}

class _AsignarVehiculoDialogState extends State<AsignarVehiculoDialog> {
  final _viajeService = ViajeService();
  final _conductorService = ConductorService();
  final _vehiculoService = VehiculoService();

  Conductor? _selectedConductor;
  Vehiculo? _selectedVehiculo;
  final _idRutaController = TextEditingController(text: '1'); // Default route for now
  
  List<Conductor> _conductores = [];
  List<Vehiculo> _vehiculos = [];
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
      ]);
      setState(() {
        _conductores = (results[0] as List<Conductor>).where((c) => c.disponible).toList();
        _vehiculos = (results[1] as List<Vehiculo>).where((v) => v.estado.toUpperCase() == 'DISPONIBLE').toList();
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
    if (_selectedConductor == null || _selectedVehiculo == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _viajeService.planificarViaje({
        'id': DateTime.now().millisecondsSinceEpoch.toString(), // ID temporal
        'idConductor': _selectedConductor!.id,
        'placa': _selectedVehiculo!.placa,
        'idRuta': _idRutaController.text,
      });

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
    return AlertDialog(
      title: const Text('Asignar Vehículo y Conductor'),
      content: _isLoadingData 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Conductor>(
                value: _selectedConductor,
                decoration: const InputDecoration(labelText: 'Seleccionar Conductor'),
                items: _conductores.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.nombre),
                )).toList(),
                onChanged: (v) => setState(() => _selectedConductor = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Vehiculo>(
                value: _selectedVehiculo,
                decoration: const InputDecoration(labelText: 'Seleccionar Vehículo'),
                items: _vehiculos.map((v) => DropdownMenuItem(
                  value: v,
                  child: Text('${v.marca} - ${v.placa}'),
                )).toList(),
                onChanged: (v) => setState(() => _selectedVehiculo = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _idRutaController,
                decoration: const InputDecoration(labelText: 'ID de Ruta'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _selectedConductor == null || _selectedVehiculo == null 
            ? null 
            : _submit,
          child: _isSubmitting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Text('Asignar'),
        ),
      ],
    );
  }
}
