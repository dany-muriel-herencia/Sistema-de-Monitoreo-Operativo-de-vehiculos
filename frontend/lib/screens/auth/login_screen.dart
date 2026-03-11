import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import '../driver/driver_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  int _cantidadDeIntentos = 0;
  bool _mostrarPassword = false;
  bool _estaBloqueado = false;

  bool _verificarBloqueo() {
    if (_cantidadDeIntentos >= 4) {
      _estaBloqueado = true;
    }
    return _estaBloqueado;
  }

  bool _isLoading = false;

  void _login() async {
    if (_verificarBloqueo()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso bloqueado por demasiados intentos fallidos.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _authService.login(
        _emailController.text.trim().toLowerCase(),
        _passwordController.text.trim(),
      );

      if (result != null) {
        final user = result['usuario'];
        final rol = user['rol'];

        if (!mounted) return;

        if (rol == 'admin') {
          _cantidadDeIntentos = 0; // Reiniciar intentos al tener éxito
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else if (rol == 'conductor') {
          _cantidadDeIntentos = 0; // Reiniciar intentos al tener éxito
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DriverHomeScreen(user: user),
            ),
          );
        } else {
          throw Exception('Rol de usuario no reconocido: $rol');
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().contains('Exception:') 
          ? e.toString().substring(e.toString().indexOf(':') + 1).trim()
          : e.toString();
          
      setState(() {
        _cantidadDeIntentos++;
      });
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage), 
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/login_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: const Color(0xFF8E24ED)),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xC0512DA8), Color(0xEE8E24ED)],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.alt_route_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Control de Flota',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Monitoreo operativo en tiempo real de conductores, rutas y viajes.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Correo Electrónico',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passwordController,
                                obscureText: !_mostrarPassword,
                                enabled: !_verificarBloqueo(),
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _mostrarPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _mostrarPassword = !_mostrarPassword;
                                      });
                                    },
                                  ),
                                  errorText: _verificarBloqueo()
                                      ? 'Máximo de intentos alcanzado'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _login,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Icon(Icons.login),
                                  label: Text(
                                    _isLoading
                                        ? 'Ingresando...'
                                        : 'Iniciar Sesión',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8E24ED),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _InfoChip(
                              icon: Icons.shield_outlined,
                              text: 'Seguridad activa',
                            ),
                            _InfoChip(
                              icon: Icons.map_outlined,
                              text: 'GPS en vivo',
                            ),
                            _InfoChip(
                              icon: Icons.analytics_outlined,
                              text: 'Reportes rapidos',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
