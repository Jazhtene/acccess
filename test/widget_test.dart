import 'package:flutter_test/flutter_test.dart';
import 'package:access_mobile/mobile_app/controllers/app.dart';

void main() {
  testWidgets('Mobile app loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AccessApp());
    await tester.pumpAndSettle();
    expect(find.text('ACCESS'), findsWidgets);
  });
}
