import 'package:flutter/material.dart';
import '../services/vehiculo_service.dart';
import '../models/vehiculo.dart';

class AddVehiculoDialog extends StatefulWidget {
  final Vehiculo? vehiculo;
  const AddVehiculoDialog({super.key, this.vehiculo});

  @override
  State<AddVehiculoDialog> createState() => _AddVehiculoDialogState();
}

class _AddVehiculoDialogState extends State<AddVehiculoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = VehiculoService();
  
  late final TextEditingController _marcaController;
  late final TextEditingController _placaController;
  late final TextEditingController _modeloController;
  late final TextEditingController _capacidadController;
  late final TextEditingController _kilometrajeController;
  late final TextEditingController _anioController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _marcaController = TextEditingController(text: widget.vehiculo?.marca);
    _placaController = TextEditingController(text: widget.vehiculo?.placa);
    _modeloController = TextEditingController(text: widget.vehiculo?.modelo);
    _capacidadController = TextEditingController(text: widget.vehiculo?.capacidad.toString());
    _kilometrajeController = TextEditingController(text: widget.vehiculo?.kilometraje.toString());
    _anioController = TextEditingController(text: widget.vehiculo?.anio.toString());
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final datos = {
        'marca': _marcaController.text,
        'placa': _placaController.text.toUpperCase(),
        'modelo': _modeloController.text,
        'capacidad': int.tryParse(_capacidadController.text) ?? 5,
        'kilometraje': double.tryParse(_kilometrajeController.text) ?? 0.0,
        'año': int.tryParse(_anioController.text) ?? DateTime.now().year,
      };

      if (widget.vehiculo != null) {
        await _service.actualizarVehiculo(widget.vehiculo!.placa, datos);
      } else {
        await _service.crearVehiculo(datos);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehiculo != null;
    return AlertDialog(
      title: Text(isEditing ? 'Editar Vehículo' : 'Registrar Nuevo Vehículo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(labelText: 'Marca'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(labelText: 'Placa'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                enabled: !isEditing, // Placa no se edita usualmente como PK
              ),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: 'Modelo'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacidadController,
                      decoration: const InputDecoration(labelText: 'Capacidad'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _anioController,
                      decoration: const InputDecoration(labelText: 'Año'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _kilometrajeController,
                decoration: const InputDecoration(labelText: 'Kilometraje'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : Text(isEditing ? 'Actualizar' : 'Registrar'),
        ),
      ],
    );
  }

}
