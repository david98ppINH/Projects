import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_version/screens/registration_screen.dart';

void main() {
  testWidgets('shows the registration screen', (WidgetTester tester) async {
    await _pumpRegistrationScreen(tester);

    expect(find.text('MUNDIAL FAN FEST'), findsOneWidget);
    expect(find.text('NOMBRE'), findsOneWidget);
    expect(find.text('CORREO ELECTRÓNICO'), findsOneWidget);
    expect(find.text('JUGAR'), findsOneWidget);
    expect(find.text('AHORA'), findsOneWidget);
  });

  testWidgets('validates required registration fields', (
    WidgetTester tester,
  ) async {
    await _pumpRegistrationScreen(tester);

    await tester.tap(find.text('JUGAR'));
    await tester.pump();

    expect(find.text('Por favor ingresa tu nombre'), findsOneWidget);
    expect(find.text('Por favor ingresa tu correo'), findsOneWidget);
  });
}

Future<void> _pumpRegistrationScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(540, 960);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: RegistrationScreen(onRegister: (_) {})),
    ),
  );
}
