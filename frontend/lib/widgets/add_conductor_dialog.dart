import 'package:flutter/material.dart';
import '../services/conductor_service.dart';
import '../models/conductor.dart';

class AddConductorDialog extends StatefulWidget {
  final Conductor? conductor;
  const AddConductorDialog({super.key, this.conductor});

  @override
  State<AddConductorDialog> createState() => _AddConductorDialogState();
}

class _AddConductorDialogState extends State<AddConductorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = ConductorService();
  
  late final TextEditingController _nombreController;
  late final TextEditingController _emailController;
  late final TextEditingController _licenciaController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _sueldoController;
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.conductor?.nombre);
    _emailController = TextEditingController(text: widget.conductor?.email);
    _licenciaController = TextEditingController(text: widget.conductor?.licencia);
    _telefonoController = TextEditingController(text: widget.conductor?.telefono);
    _sueldoController = TextEditingController(text: widget.conductor?.sueldo.toString());
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final datos = {
        'nombre': _nombreController.text,
        'email': _emailController.text.trim().toLowerCase(),
        'licencia': _licenciaController.text,
        'telefono': int.tryParse(_telefonoController.text) ?? 0,
        'sueldo': double.tryParse(_sueldoController.text) ?? 0.0,
      };

      if (widget.conductor != null) {
        await _service.actualizarConductor(widget.conductor!.id, datos);
      } else {
        datos['contraseña'] = _passwordController.text.isNotEmpty 
            ? _passwordController.text 
            : 'password123';
        await _service.crearConductor(datos);
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
    final isEditing = widget.conductor != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Conductor' : 'Registrar Nuevo Conductor'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.contains('@') ? null : 'Email inválido',
              ),
              TextFormField(
                controller: _licenciaController,
                decoration: const InputDecoration(labelText: 'Número de Licencia'),
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _sueldoController,
                decoration: const InputDecoration(labelText: 'Sueldo'),
                keyboardType: TextInputType.number,
              ),
              if (!isEditing)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña (opcional)',
                    helperText: 'Por defecto: password123',
                  ),
                  obscureText: true,
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
            : Text(isEditing ? 'Guardar Cambios' : 'Registrar'),
        ),
      ],
    );
  }
}
