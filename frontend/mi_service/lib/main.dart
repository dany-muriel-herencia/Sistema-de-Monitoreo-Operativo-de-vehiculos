import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/driver/driver_dashboard.dart';
import 'screens/driver/admin_dashboard.dart';

void main() {
  // Aseguramos que Flutter esté listo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Capturamos errores globales para que no se quede la pantalla en blanco sin avisar
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoreo Flotas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.white, // Forzamos un fondo base
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      // Usamos el login como pantalla principal directamente
      home: LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/driver': (context) => DriverDashboard(),
        '/admin': (context) => AdminDashboard(),
      },
    );
  }
}