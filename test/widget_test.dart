import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eduframe/constants/theme.dart';

void main() {
  testWidgets('light theme builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const Scaffold(
          body: Center(child: Text('EduFrame')),
        ),
      ),
    );
    expect(find.text('EduFrame'), findsOneWidget);
  });
}
