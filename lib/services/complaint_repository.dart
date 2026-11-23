import 'dart:convert';
import 'dart:io';
import '../models/complaint.dart';

abstract class ComplaintRepository {
  bool get supportsPdfExport;
  Future<List<Complaint>> listComplaints();
  Future<List<CorrectiveAction>> listActions();
  Future<List<ComplaintEvent>> listEvents(int complaintId);
  Future<Complaint> createComplaint(Map<String, dynamic> data);
  Future<Complaint> updateContainment(int id, String notes, String actor);
  Future<Complaint> updateInvestigation(int id, String cause, String actor);
  Future<Complaint> updateVerification(int id, String result, String notes, String reviewer, String actor);
  Future<Complaint> transition(int id, String status, String actor);
  Future<CorrectiveAction> createAction(int complaintId, String title, String owner, DateTime dueDate, String actor);
  Future<CorrectiveAction> updateAction(int actionId, String status, String actor);
  Future<void> updateCosts(int complaintId, Map<String, double> costs, String actor);
  Future<String> exportReport(int complaintId, String reference);
}

class ApiComplaintRepository implements ComplaintRepository {
  final String baseUrl;
  ApiComplaintRepository(this.baseUrl);
  @override
  bool get supportsPdfExport => true;

  Future<dynamic> _request(String method, String path, [Map<String, dynamic>? payload]) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.openUrl(method, Uri.parse('$baseUrl$path'));
      request.headers.contentType = ContentType.json;
      if (payload != null) request.write(jsonEncode(payload));
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String reason = body;
        try {
          final decoded = jsonDecode(body);
          reason = decoded is Map && decoded.containsKey('detail') ? decoded['detail'].toString() : body;
        } catch (_) {}
        throw HttpException('API ${response.statusCode}: $reason');
      }
      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<List<Complaint>> listComplaints() async => (await _request('GET', '/api/complaints') as List)
      .map((item) => Complaint.fromJson(item as Map<String, dynamic>)).toList();
  @override
  Future<List<CorrectiveAction>> listActions() async => (await _request('GET', '/api/actions') as List)
      .map((item) => CorrectiveAction.fromJson(item as Map<String, dynamic>)).toList();
  @override
  Future<List<ComplaintEvent>> listEvents(int complaintId) async =>
      (await _request('GET', '/api/complaints/$complaintId/events') as List)
          .map((item) => ComplaintEvent.fromJson(item as Map<String, dynamic>)).toList();
  @override
  Future<Complaint> createComplaint(Map<String, dynamic> data) async => Complaint.fromJson(
      await _request('POST', '/api/complaints', data) as Map<String, dynamic>);
  @override
  Future<Complaint> updateContainment(int id, String notes, String actor) async => Complaint.fromJson(
      await _request('PATCH', '/api/complaints/$id/containment', {'containment_action': notes, 'actor': actor}) as Map<String, dynamic>);
  @override
  Future<Complaint> updateInvestigation(int id, String cause, String actor) async => Complaint.fromJson(
      await _request('PATCH', '/api/complaints/$id/investigation', {'root_cause': cause, 'actor': actor}) as Map<String, dynamic>);
  @override
  Future<Complaint> updateVerification(int id, String result, String notes, String reviewer, String actor) async => Complaint.fromJson(
      await _request('PATCH', '/api/complaints/$id/verification', {
        'verification_result': result, 'verification_notes': notes, 'verified_by': reviewer, 'actor': actor,
      }) as Map<String, dynamic>);
  @override
  Future<Complaint> transition(int id, String status, String actor) async => Complaint.fromJson(
      await _request('POST', '/api/complaints/$id/transition', {'status': status, 'actor': actor}) as Map<String, dynamic>);
  @override
  Future<CorrectiveAction> createAction(int complaintId, String title, String owner, DateTime dueDate, String actor) async => CorrectiveAction.fromJson(
      await _request('POST', '/api/complaints/$complaintId/actions', {
        'title': title, 'owner': owner, 'due_date': _date(dueDate), 'actor': actor,
      }) as Map<String, dynamic>);
  @override
  Future<CorrectiveAction> updateAction(int actionId, String status, String actor) async => CorrectiveAction.fromJson(
      await _request('PATCH', '/api/actions/$actionId', {'status': status, 'actor': actor}) as Map<String, dynamic>);

  @override
  Future<void> updateCosts(int complaintId, Map<String, double> costs, String actor) async {
    await _request('PATCH', '/api/complaints/$complaintId/costs', {...costs, 'actor': actor});
  }

  @override
  Future<String> exportReport(int complaintId, String reference) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(Uri.parse('$baseUrl/api/complaints/$complaintId/report.pdf'));
      final response = await request.close();
      if (response.statusCode != 200) throw HttpException('PDF export failed: HTTP ${response.statusCode}');
      final bytes = await response.fold<List<int>>([], (previous, chunk) => previous..addAll(chunk));
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? Directory.current.path;
      final downloads = Directory('$home${Platform.pathSeparator}Downloads');
      final destination = await downloads.exists() ? downloads : Directory.current;
      final filename = reference.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${destination.path}${Platform.pathSeparator}$filename.pdf');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } finally {
      client.close(force: true);
    }
  }
}

String _date(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class DemoComplaintRepository implements ComplaintRepository {
  @override
  bool get supportsPdfExport => false;
  int _complaintSequence = 5;
  int _actionSequence = 5;
  int _eventSequence = 5;

  final List<Complaint> _complaints = [
    _demoComplaint(1, 'Surface scratches on protective cover', 'Northstar Components', 'NC-1042', 'Visual defect', 'Medium', 'Open', 600, 31, '', '', 'Not reviewed', '', '', 2),
    _demoComplaint(2, 'Dimensional deviation on housing', 'Atlas Mobility', 'AM-2055', 'Dimensional', 'High', 'In Progress', 240, 47, 'Quarantine the lot and inspect 100% of stock.', 'Fixture calibration drift.', 'Not reviewed', '', '', 5),
    _demoComplaint(3, 'Incomplete packaging labels', 'Orion Industrial', 'OI-3410', 'Packaging', 'Low', 'Closed', 150, 12, 'Hold and relabel outgoing stock.', 'Printer feed roller maintenance overdue.', 'Effective', 'Sample audit passed.', 'Jordan Lee', 6),
    _demoComplaint(4, 'Discoloration within production lot', 'Northstar Components', 'NC-1178', 'Visual defect', 'Medium', 'Open', 890, 94, '', '', 'Not reviewed', '', '', 9),
    _demoComplaint(5, 'Assembly fit issue', 'Atlas Mobility', 'AM-2088', 'Assembly', 'High', 'Pending Verification', 480, 58, 'Segregate the affected lot and perform fit checks.', 'Tool alignment drift after changeover.', 'Not reviewed', '', '', 11),
  ];
  final List<CorrectiveAction> _actions = [
    CorrectiveAction(id: 1, complaintId: 2, title: 'Review measurement fixture calibration', owner: 'Taylor Reed', dueDate: DateTime(2026, 11, 20), status: 'In Progress'),
    CorrectiveAction(id: 2, complaintId: 2, title: 'Retrain shift on first-off inspection', owner: 'Alex Morgan', dueDate: DateTime(2026, 11, 25), status: 'Open'),
    CorrectiveAction(id: 3, complaintId: 3, title: 'Update packaging label checklist', owner: 'Alex Morgan', dueDate: DateTime(2026, 11, 12), status: 'Completed'),
    CorrectiveAction(id: 4, complaintId: 5, title: 'Realign assembly fixture', owner: 'Taylor Reed', dueDate: DateTime(2026, 11, 17), status: 'Completed'),
    CorrectiveAction(id: 5, complaintId: 5, title: 'Confirm fit with a sample lot', owner: 'Jordan Lee', dueDate: DateTime(2026, 11, 18), status: 'Completed'),
  ];
  final List<ComplaintEvent> _events = List.generate(5, (index) => ComplaintEvent(
    id: index + 1, complaintId: index + 1, eventType: 'seed', message: 'Fictional demo case loaded',
    actor: 'Demo system', createdAt: DateTime(2026, 11, index + 2),
  ));

  DemoComplaintRepository() {
    _seedPortfolioCases();
    for (var index = 0; index < _complaints.length; index++) {
      final complaint = _complaints[index];
      final hasCosts = complaint.status != 'Open';
      final base = complaint.rejectedQuantity * (complaint.severity == 'High' ? 19.0 : 8.0);
      _complaints[index] = complaint.copyWith(
        estimatedCost: base * 1.25,
        scrapCost: hasCosts ? base * 0.60 : null,
        reworkCost: hasCosts ? base * 0.25 : null,
        inspectionCost: hasCosts ? base * 0.15 : null,
        otherCost: hasCosts ? (index % 4) * 25.0 : null,
      );
    }
  }

  void _seedPortfolioCases() {
    const titles = [
      'Surface finish inconsistency', 'Incorrect assembly clearance',
      'Packaging label mismatch', 'Dimensional tolerance exceeded',
      'Material discoloration', 'Missing component in delivery',
      'Surface contamination detected', 'Incorrect hole positioning',
      'Incomplete production documentation', 'Excessive component deformation',
      'Damaged transportation packaging', 'Functional inspection failure',
    ];
    const categories = [
      'Visual defect', 'Assembly', 'Packaging', 'Dimensional',
      'Visual defect', 'Missing parts', 'Contamination', 'Dimensional',
      'Documentation', 'Dimensional', 'Packaging', 'Functional',
    ];
    const customers = [
      'Northstar Components', 'Atlas Mobility', 'Orion Industrial',
      'Summit Engineering', 'Vertex Systems', 'Helix Manufacturing',
    ];
    const owners = ['Jordan Lee', 'Taylor Reed', 'Alex Morgan', 'Sam Carter'];
    final statuses = <String>[
      ...List.filled(10, 'Open'),
      ...List.filled(17, 'In Progress'),
      ...List.filled(7, 'Pending Verification'),
      ...List.filled(11, 'Closed'),
    ];
    for (var id = 6; id <= 50; id++) {
      final index = id - 6;
      final issue = index % titles.length;
      final status = statuses[index];
      final owner = owners[index % owners.length];
      final created = DateTime(2026, 1, 1).add(Duration(days: index * 7));
      final updated = created.add(const Duration(days: 3));
      final affected = 100 + (id * 37) % 900;
      final rejected = 5 + (id * 11) % 80;
      final investigated = status != 'Open';
      final readyForVerification = status == 'Pending Verification' || status == 'Closed';
      final complaint = Complaint(
        id: id,
        reference: 'CMP-2026-${id.toString().padLeft(4, '0')}',
        title: titles[issue],
        customer: customers[index % customers.length],
        itemCode: 'QF-${1000 + id * 17}',
        category: categories[issue],
        severity: ['Low', 'Medium', 'High'][index % 3],
        status: status,
        description: 'Fictional quality incident identified during routine inspection of production lot ${1000 + id}.',
        reporter: 'Alex Morgan',
        assignedTo: owner,
        affectedQuantity: affected,
        rejectedQuantity: rejected,
        containmentAction: investigated ? 'Affected stock isolated and inspection initiated.' : '',
        rootCause: readyForVerification ? 'Process variation identified during investigation.' : '',
        verificationResult: status == 'Closed' ? 'Effective' : 'Not reviewed',
        verificationNotes: status == 'Closed' ? 'Follow-up inspection confirmed effectiveness.' : '',
        verifiedBy: status == 'Closed' ? 'Jordan Lee' : '',
        createdAt: created,
        updatedAt: updated,
      );
      _complaints.add(complaint);
      _events.add(ComplaintEvent(
        id: ++_eventSequence, complaintId: id, eventType: 'created',
        message: 'Fictional complaint registered', actor: 'Demo system', createdAt: created,
      ));
      if (investigated) {
        _actions.add(CorrectiveAction(
          id: ++_actionSequence,
          complaintId: id,
          title: 'Review process controls for ${categories[issue].toLowerCase()}',
          owner: owner,
          dueDate: created.add(const Duration(days: 14)),
          status: readyForVerification ? 'Completed' : 'In Progress',
        ));
        _events.add(ComplaintEvent(
          id: ++_eventSequence, complaintId: id, eventType: 'status',
          message: 'Status changed to $status', actor: 'Demo system', createdAt: updated,
        ));
      }
    }
    _complaintSequence = 50;
  }

  Complaint _get(int id) {
    final index = _complaints.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Complaint not found.');
    return _complaints[index];
  }

  void _replace(Complaint complaint) {
    final index = _complaints.indexWhere((item) => item.id == complaint.id);
    _complaints[index] = complaint;
  }

  void _event(int id, String type, String message, String actor) => _events.add(ComplaintEvent(
    id: ++_eventSequence, complaintId: id, eventType: type, message: message,
    actor: actor, createdAt: DateTime.now(),
  ));

  void _editable(Complaint complaint) {
    if (complaint.status == 'Closed') throw StateError('Closed complaints are read-only.');
  }

  @override
  Future<List<Complaint>> listComplaints() async => List.unmodifiable(_complaints);
  @override
  Future<List<CorrectiveAction>> listActions() async => List.unmodifiable(_actions);
  @override
  Future<List<ComplaintEvent>> listEvents(int complaintId) async => List.unmodifiable(
      _events.where((event) => event.complaintId == complaintId).toList()
        ..sort((a, b) => b.id.compareTo(a.id)));

  @override
  Future<Complaint> createComplaint(Map<String, dynamic> data) async {
    final affected = data['affected_quantity'] as int;
    final rejected = data['rejected_quantity'] as int;
    if (affected < 1 || rejected < 0 || rejected > affected) throw StateError('Check affected and rejected quantities.');
    final id = ++_complaintSequence;
    final complaint = Complaint(
      id: id, reference: 'CMP-${DateTime.now().year}-${id.toString().padLeft(4, '0')}',
      title: data['title'] as String, customer: data['customer'] as String,
      itemCode: data['item_code'] as String, category: data['category'] as String,
      severity: data['severity'] as String, status: 'Open', description: data['description'] as String,
      reporter: data['reporter'] as String, assignedTo: data['assigned_to'] as String,
      affectedQuantity: affected, rejectedQuantity: rejected,
      containmentAction: '', rootCause: '', verificationResult: 'Not reviewed',
      verificationNotes: '', verifiedBy: '', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      estimatedCost: (data['estimated_cost'] as num?)?.toDouble(),
    );
    _complaints.add(complaint);
    _event(id, 'created', 'Complaint registered', complaint.reporter);
    return complaint;
  }

  @override
  Future<Complaint> updateContainment(int id, String notes, String actor) async {
    final current = _get(id);
    _editable(current);
    if (current.status == 'Pending Verification') throw StateError('Return to investigation before changing containment.');
    final updated = current.copyWith(containmentAction: notes);
    _replace(updated);
    _event(id, 'containment', 'Containment notes updated', actor);
    return updated;
  }

  @override
  Future<Complaint> updateInvestigation(int id, String cause, String actor) async {
    final current = _get(id);
    _editable(current);
    if (current.status == 'Pending Verification') throw StateError('Return to investigation first.');
    final updated = current.copyWith(rootCause: cause);
    _replace(updated);
    _event(id, 'investigation', 'Root cause documentation updated', actor);
    return updated;
  }

  @override
  Future<Complaint> updateVerification(int id, String result, String notes, String reviewer, String actor) async {
    final current = _get(id);
    if (current.status != 'Pending Verification') throw StateError('Verification is not available yet.');
    final updated = current.copyWith(verificationResult: result, verificationNotes: notes, verifiedBy: reviewer);
    _replace(updated);
    _event(id, 'verification', 'Effectiveness result: $result', actor);
    return updated;
  }

  @override
  Future<Complaint> transition(int id, String status, String actor) async {
    final current = _get(id);
    final actions = _actions.where((action) => action.complaintId == id).toList();
    final allowed = switch (current.status) {
      'Open' => ['In Progress'], 'In Progress' => ['Pending Verification'],
      'Pending Verification' => ['Closed', 'In Progress'], _ => <String>[],
    };
    if (!allowed.contains(status)) throw StateError('Invalid workflow transition.');
    if (current.status == 'Open' && current.containmentAction.trim().isEmpty) throw StateError('Save the containment action first.');
    if (current.status == 'In Progress' && (current.rootCause.trim().isEmpty || actions.isEmpty || actions.any((action) => action.status != 'Completed'))) {
      throw StateError('Document the root cause and complete every corrective action first.');
    }
    if (status == 'Closed' && (current.verificationResult != 'Effective' || current.verificationNotes.trim().isEmpty || current.verifiedBy.trim().isEmpty)) {
      throw StateError('Record effective verification, notes and reviewer before closure.');
    }
    if (current.status == 'Pending Verification' && status == 'In Progress' && current.verificationResult != 'Ineffective') {
      throw StateError('Mark verification as ineffective before returning to investigation.');
    }
    final updated = current.copyWith(
      status: status,
      verificationResult: current.status == 'Pending Verification' && status == 'In Progress' ? 'Not reviewed' : null,
      verificationNotes: current.status == 'Pending Verification' && status == 'In Progress' ? '' : null,
      verifiedBy: current.status == 'Pending Verification' && status == 'In Progress' ? '' : null,
    );
    _replace(updated);
    _event(id, 'status', 'Status changed: ${current.status} → $status', actor);
    return updated;
  }

  @override
  Future<CorrectiveAction> createAction(int complaintId, String title, String owner, DateTime dueDate, String actor) async {
    final complaint = _get(complaintId);
    _editable(complaint);
    if (complaint.status == 'Pending Verification') throw StateError('Return to investigation before adding actions.');
    final action = CorrectiveAction(id: ++_actionSequence, complaintId: complaintId, title: title, owner: owner,
      dueDate: dueDate, status: 'Open');
    _actions.add(action);
    _event(complaintId, 'action', 'Corrective action created: $title', actor);
    return action;
  }

  @override
  Future<CorrectiveAction> updateAction(int actionId, String status, String actor) async {
    final index = _actions.indexWhere((action) => action.id == actionId);
    if (index < 0) throw StateError('Corrective action not found.');
    final previous = _actions[index];
    final complaint = _get(previous.complaintId);
    _editable(complaint);
    if (complaint.status == 'Pending Verification') throw StateError('Return to investigation first.');
    final updated = previous.copyWith(status: status);
    _actions[index] = updated;
    _event(previous.complaintId, 'action', 'Action status changed: ${previous.status} → $status', actor);
    return updated;
  }

  @override
  Future<void> updateCosts(int complaintId, Map<String, double> costs, String actor) async {
    final current = _get(complaintId);
    _editable(current);
    for (final value in costs.values) {
      if (!value.isFinite || value < 0) throw StateError('Costs must be non-negative finite numbers.');
    }
    final updated = current.copyWith(
      scrapCost: costs['scrap_cost'], reworkCost: costs['rework_cost'],
      inspectionCost: costs['inspection_cost'], otherCost: costs['other_cost'],
    );
    _replace(updated);
    _event(complaintId, 'costs', 'Quality costs updated', actor);
  }

  @override
  Future<String> exportReport(int complaintId, String reference) async =>
      throw UnsupportedError('PDF export is available in API mode.');
}

Complaint _demoComplaint(int id, String title, String customer, String item, String category,
    String severity, String status, int affected, int rejected, String containment,
    String rootCause, String verificationResult, String verificationNotes, String verifiedBy, int day) {
  return Complaint(
    id: id, reference: 'CMP-2026-${id.toString().padLeft(4, '0')}',
    title: title, customer: customer, itemCode: item, category: category,
    severity: severity, status: status,
    description: 'Fictional case: $title was reported during a routine quality inspection.',
    reporter: 'Alex Morgan', assignedTo: 'Jordan Lee',
    affectedQuantity: affected, rejectedQuantity: rejected,
    containmentAction: containment, rootCause: rootCause,
    verificationResult: verificationResult, verificationNotes: verificationNotes,
    verifiedBy: verifiedBy, createdAt: DateTime(2026, 11, day), updatedAt: DateTime(2026, 11, day),
  );
}
