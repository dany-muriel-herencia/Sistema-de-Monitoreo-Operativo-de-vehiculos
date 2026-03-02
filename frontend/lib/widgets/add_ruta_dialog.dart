import 'package:flutter/material.dart';
import '../services/ruta_service.dart';
import '../models/ruta.dart';

class AddRutaDialog extends StatefulWidget {
  final Ruta? ruta;
  const AddRutaDialog({super.key, this.ruta});

  @override
  State<AddRutaDialog> createState() => _AddRutaDialogState();
}

class _AddRutaDialogState extends State<AddRutaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = RutaService();
  
  late final TextEditingController _nombreController;
  late final TextEditingController _distanciaController;
  late final TextEditingController _duracionController;
  
  // Lista simple de puntos
  List<TextEditingController> _latControllers = [];
  List<TextEditingController> _lngControllers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.ruta?.nombre);
    _distanciaController = TextEditingController(text: widget.ruta?.distanciaTotal.toString());
    _duracionController = TextEditingController(text: widget.ruta?.duracionEstimadaMinutos.toString());

    if (widget.ruta != null && widget.ruta!.puntos.isNotEmpty) {
      for (var p in widget.ruta!.puntos) {
        _latControllers.add(TextEditingController(text: p.latitud.toString()));
        _lngControllers.add(TextEditingController(text: p.longitud.toString()));
      }
    } else {
      _latControllers.add(TextEditingController());
      _lngControllers.add(TextEditingController());
    }
  }

  void _addPoint() {
    setState(() {
      _latControllers.add(TextEditingController());
      _lngControllers.add(TextEditingController());
    });
  }

  void _removePoint(int index) {
    if (_latControllers.length > 1) {
      setState(() {
        _latControllers.removeAt(index);
        _lngControllers.removeAt(index);
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> puntos = [];
      for (int i = 0; i < _latControllers.length; i++) {
        puntos.add({
          'lat': double.parse(_latControllers[i].text),
          'lng': double.parse(_lngControllers[i].text),
          'orden': i + 1,
        });
      }

      final datos = {
        'nombre': _nombreController.text,
        'distanciaTotal': double.parse(_distanciaController.text),
        'duracionEstimadaMinutos': int.parse(_duracionController.text),
        'puntos': puntos,
      };


      if (widget.ruta != null) {
        await _service.actualizarRuta(widget.ruta!.id, datos);
      } else {
        await _service.crearRuta(datos);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ruta != null;
    return AlertDialog(
      title: Text(isEditing ? 'Editar Ruta' : 'Crear Nueva Ruta'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre de la Ruta'),
                  validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _distanciaController,
                        decoration: const InputDecoration(labelText: 'Distancia (KM)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _duracionController,
                        decoration: const InputDecoration(labelText: 'Duración (min)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('PUNTOS GEOGRÁFICOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const Divider(),
                ...List.generate(_latControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latControllers[index],
                            decoration: InputDecoration(labelText: 'Latitud ${index + 1}'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            enabled: !isEditing,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _lngControllers[index],
                            decoration: InputDecoration(labelText: 'Longitud ${index + 1}'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            enabled: !isEditing,
                          ),
                        ),
                        if (!isEditing)
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removePoint(index),
                          )
                      ],
                    ),
                  );
                }),
                if (!isEditing)
                  TextButton.icon(
                    onPressed: _addPoint,
                    icon: const Icon(Icons.add_location),
                    label: const Text('Agregar Punto'),
                  ),
              ],
            ),
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
            : Text(isEditing ? 'Actualizar' : 'Guardar Ruta'),
        ),
      ],
    );
  }

}
