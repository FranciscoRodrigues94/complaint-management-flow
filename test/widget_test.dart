import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('Dashboard loads fictional complaints in offline demo mode', (tester) async {
    await tester.pumpWidget(const ComplaintManagementApp());
    await tester.pumpAndSettle();
    expect(find.text('Quality dashboard'), findsOneWidget);
    expect(find.text('Total cases'), findsOneWidget);
  });
}
