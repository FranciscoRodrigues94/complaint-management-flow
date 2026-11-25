import 'package:flutter_test/flutter_test.dart';
import 'package:qualityflow/services/complaint_repository.dart';

void main() {
  test('Complaint workflow rejects skipping containment or actions', () async {
    final repo = DemoComplaintRepository();
    final complaint = await repo.createComplaint({
      'title': 'Demo incident', 'customer': 'Example Components', 'item_code': 'EX-001',
      'category': 'Assembly', 'severity': 'Medium', 'description': 'Test incident with faulty assembly.',
      'reporter': 'Alex Morgan', 'assigned_to': 'Jordan Lee',
      'affected_quantity': 100, 'rejected_quantity': 3,
    });
    await expectLater(repo.transition(complaint.id, 'In Progress', 'Alex Morgan'), throwsStateError);
    await repo.updateContainment(complaint.id, 'Quarantine affected units', 'Alex Morgan');
    await repo.transition(complaint.id, 'In Progress', 'Alex Morgan');
    await expectLater(repo.transition(complaint.id, 'Pending Verification', 'Alex Morgan'), throwsStateError);
    await repo.updateInvestigation(complaint.id, 'Incorrect tool position', 'Alex Morgan');
    final action = await repo.createAction(complaint.id, 'Correct tool position', 'Jordan Lee', DateTime.now(), 'Alex Morgan');
    await expectLater(repo.transition(complaint.id, 'Pending Verification', 'Alex Morgan'), throwsStateError);
    await repo.updateAction(action.id, 'Completed', 'Jordan Lee');
    await repo.transition(complaint.id, 'Pending Verification', 'Alex Morgan');
    await expectLater(repo.transition(complaint.id, 'Closed', 'Alex Morgan'), throwsStateError);
    await repo.updateVerification(complaint.id, 'Effective', 'Sample verification completed', 'Alex Morgan', 'Alex Morgan');
    final closed = await repo.transition(complaint.id, 'Closed', 'Alex Morgan');
    expect(closed.status, 'Closed');
    expect((await repo.listEvents(complaint.id)).length, greaterThan(6));
  });

  test('Rejected quantity cannot exceed affected quantity', () async {
    final repo = DemoComplaintRepository();
    await expectLater(repo.createComplaint({
      'title': 'Incorrect quantity', 'customer': 'Example Components', 'item_code': 'EX-002',
      'category': 'Other', 'severity': 'Low', 'description': 'Incorrect count entered.',
      'reporter': 'Alex Morgan', 'assigned_to': 'Jordan Lee',
      'affected_quantity': 5, 'rejected_quantity': 10,
    }), throwsStateError);
  });
}
