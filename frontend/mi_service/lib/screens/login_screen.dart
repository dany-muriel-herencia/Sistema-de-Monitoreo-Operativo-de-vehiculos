import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/viaje_provider.dart';
import 'driver/driver_dashboard.dart';
import 'driver/admin_dashboard.dart';

class LoginScreen extends ConsumerStatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null) {
        if (next.user!.rol == 'admin') {
          ref.read(adminProvider.notifier).cargarDatos();
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          ref.read(viajeProvider.notifier).cargarViaje();
          Navigator.pushReplacementNamed(context, '/driver');
        }
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Bienvenido', style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (v) => v!.contains('@') ? null : 'Email inválido',
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                      validator: (v) => v!.length >= 3 ? null : 'Mínimo 3 caracteres',
                    ),
                    SizedBox(height: 24),
                    if (authState.isLoading)
                      CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await authNotifier.login(
                              _emailController.text,
                              _passwordController.text,
                            );
                          }
                        },
                        child: Text('Iniciar sesión'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 45),
                        ),
                      ),
                    if (authState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(authState.error!, style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}