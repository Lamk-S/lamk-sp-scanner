import 'package:flutter_test/flutter_test.dart';

import 'package:scanneo_app/scanner_app.dart';

void main() {
  testWidgets('La aplicación se construye correctamente', (WidgetTester tester) async {
    // Construye la app
    await tester.pumpWidget(const ScannerApp());

    // Verifica que la app inicia y muestra el título o el botón de escanear
    expect(find.text('ScanNeo POS'), findsOneWidget);
  });
}