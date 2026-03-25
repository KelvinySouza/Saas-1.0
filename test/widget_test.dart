// Widget smoke test (não inicializa Supabase — o app real exige --dart-define).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke: MaterialApp monta', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('ok')),
        ),
      ),
    );
    expect(find.text('ok'), findsOneWidget);
  });
}
