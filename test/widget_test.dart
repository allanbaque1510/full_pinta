// Smoke test: la app arranca y muestra el splash mientras resuelve la
// sesión, sin que ninguna llamada de red real se dispare todavía (el
// controlador de sesión solo se activa en un microtask desde `FullPintaApp`).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:full_pinta/app.dart';
import 'package:full_pinta/core/widgets/fullpinta_wordmark.dart';

void main() {
  testWidgets('La app arranca y muestra el splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FullPintaApp()));
    await tester.pump();

    expect(find.byType(FullPintaWordmark), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
