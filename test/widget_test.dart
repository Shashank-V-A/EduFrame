import 'package:flutter_test/flutter_test.dart';
import 'package:eduframe/main.dart';

void main() {
  testWidgets('EduFrame launches', (tester) async {
    await tester.pumpWidget(const EduFrameApp());
    expect(find.text('EduFrame'), findsOneWidget);
  });
}
