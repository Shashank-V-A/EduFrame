import 'package:flutter_test/flutter_test.dart';
import 'package:planbook/main.dart';

void main() {
  testWidgets('PlanBook launches', (tester) async {
    await tester.pumpWidget(const PlanBookApp());
    expect(find.text('PlanBook'), findsOneWidget);
  });
}
