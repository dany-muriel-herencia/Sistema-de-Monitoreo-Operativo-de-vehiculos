import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_service/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
