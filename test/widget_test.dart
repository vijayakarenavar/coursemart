import 'package:flutter_test/flutter_test.dart';
import 'package:coursemart_app/main.dart';

void main() {
  testWidgets('CourseMart app loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CourseMartApp());
    expect(find.text('Welcome back! 👋'), findsOneWidget);
    expect(find.text('Sign in to continue learning'), findsOneWidget);
  });
}
