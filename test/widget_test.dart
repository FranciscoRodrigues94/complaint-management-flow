import 'package:flutter_test/flutter_test.dart';
import 'package:qualityflow/main.dart';

void main() {
  testWidgets('Dashboard displays its main sections', (tester) async {
    await tester.pumpWidget(const ComplaintManagementApp());
    await tester.pumpAndSettle();
    expect(find.text('Quality dashboard'), findsOneWidget);
    expect(find.text('Total cases'), findsOneWidget);
  });
}
