import 'package:flutter/material.dart';
import '../services/conductor_service.dart';

class AddConductorDialog extends StatefulWidget {
  const AddConductorDialog({super.key});

  @override
  State<AddConductorDialog> createState() => _AddConductorDialogState();
}

class _AddConductorDialogState extends State<AddConductorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = ConductorService();
  
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenciaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _sueldoController = TextEditingController();
  final _edadController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _service.crearConductor({
        'nombre': _nombreController.text,
        'email': _emailController.text.trim().toLowerCase(),
        'licencia': _licenciaController.text,
        'telefono': int.tryParse(_telefonoController.text) ?? 0,
        'sueldo': double.tryParse(_sueldoController.text) ?? 0.0,
        'edad': int.tryParse(_edadController.text) ?? 0,
        'contraseña': _passwordController.text.isNotEmpty 
            ? _passwordController.text 
            : 'password123',
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
      title: const Text('Registrar Nuevo Conductor'),
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _edadController,
                      decoration: const InputDecoration(labelText: 'Edad'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _sueldoController,
                decoration: const InputDecoration(labelText: 'Sueldo'),
                keyboardType: TextInputType.number,
              ),
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
            : const Text('Registrar'),
        ),
      ],
    );
  }
}
