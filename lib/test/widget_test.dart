import 'package:flutter_test/flutter_test.dart';
import 'package:legal_issue_solver_bot/app.dart';

void main() {
  testWidgets('App starts and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Legal Issue Solver Bot'), findsOneWidget);
  });
}
