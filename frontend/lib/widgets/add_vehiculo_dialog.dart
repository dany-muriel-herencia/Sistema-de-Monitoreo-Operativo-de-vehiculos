import 'package:flutter/material.dart';
import '../services/vehiculo_service.dart';

class AddVehiculoDialog extends StatefulWidget {
  const AddVehiculoDialog({super.key});

  @override
  State<AddVehiculoDialog> createState() => _AddVehiculoDialogState();
}

class _AddVehiculoDialogState extends State<AddVehiculoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = VehiculoService();
  
  final _marcaController = TextEditingController();
  final _placaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _kilometrajeController = TextEditingController();
  final _anioController = TextEditingController();

  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _service.crearVehiculo({
        'marca': _marcaController.text,
        'placa': _placaController.text.toUpperCase(),
        'modelo': _modeloController.text,
        'capacidad': int.tryParse(_capacidadController.text) ?? 5,
        'kilometraje': double.tryParse(_kilometrajeController.text) ?? 0.0,
        'año': int.tryParse(_anioController.text) ?? DateTime.now().year,
      });

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
    return AlertDialog(
      title: const Text('Registrar Nuevo Vehículo'),
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
                decoration: const InputDecoration(labelText: 'Kilometraje Inicial'),
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
            : const Text('Registrar'),
        ),
      ],
    );
  }
}
