import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanshvriksh/app/vanshvriksh_app.dart';

void main() {
  testWidgets('renders the VanshVriksh dashboard shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: VanshVrikshApp()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
