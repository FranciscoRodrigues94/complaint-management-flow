class Complaint {
  final int id;
  final String reference;
  final String title;
  final String customer;
  final String itemCode;
  final String category;
  final String severity;
  final String status;
  final String description;
  final String reporter;
  final String assignedTo;
  final int affectedQuantity;
  final int rejectedQuantity;
  final String containmentAction;
  final String rootCause;
  final String verificationResult;
  final String verificationNotes;
  final String verifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Complaint({
    required this.id, required this.reference, required this.title, required this.customer,
    required this.itemCode, required this.category, required this.severity, required this.status,
    required this.description, required this.reporter, required this.assignedTo,
    required this.affectedQuantity, required this.rejectedQuantity,
    required this.containmentAction, required this.rootCause, required this.verificationResult,
    required this.verificationNotes, required this.verifiedBy,
    required this.createdAt, required this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
    id: (json['id'] as num).toInt(),
    reference: json['reference'] as String,
    title: json['title'] as String,
    customer: json['customer'] as String,
    itemCode: json['item_code'] as String,
    category: json['category'] as String,
    severity: json['severity'] as String,
    status: json['status'] as String,
    description: json['description'] as String,
    reporter: json['reporter'] as String,
    assignedTo: json['assigned_to'] as String,
    affectedQuantity: (json['affected_quantity'] as num).toInt(),
    rejectedQuantity: (json['rejected_quantity'] as num).toInt(),
    containmentAction: json['containment_action'] as String? ?? '',
    rootCause: json['root_cause'] as String? ?? '',
    verificationResult: json['verification_result'] as String? ?? 'Not reviewed',
    verificationNotes: json['verification_notes'] as String? ?? '',
    verifiedBy: json['verified_by'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Complaint copyWith({String? status, String? containmentAction, String? rootCause,
      String? verificationResult, String? verificationNotes, String? verifiedBy}) => Complaint(
    id: id, reference: reference, title: title, customer: customer, itemCode: itemCode,
    category: category, severity: severity, status: status ?? this.status,
    description: description, reporter: reporter, assignedTo: assignedTo,
    affectedQuantity: affectedQuantity, rejectedQuantity: rejectedQuantity,
    containmentAction: containmentAction ?? this.containmentAction,
    rootCause: rootCause ?? this.rootCause,
    verificationResult: verificationResult ?? this.verificationResult,
    verificationNotes: verificationNotes ?? this.verificationNotes,
    verifiedBy: verifiedBy ?? this.verifiedBy,
    createdAt: createdAt, updatedAt: DateTime.now(),
  );
}

class CorrectiveAction {
  final int id;
  final int complaintId;
  final String title;
  final String owner;
  final DateTime dueDate;
  final String status;
  final DateTime? completedAt;

  const CorrectiveAction({required this.id, required this.complaintId, required this.title,
    required this.owner, required this.dueDate, required this.status, this.completedAt});

  factory CorrectiveAction.fromJson(Map<String, dynamic> json) => CorrectiveAction(
    id: (json['id'] as num).toInt(),
    complaintId: (json['complaint_id'] as num).toInt(),
    title: json['title'] as String,
    owner: json['owner'] as String,
    dueDate: DateTime.parse(json['due_date'] as String),
    status: json['status'] as String,
    completedAt: json['completed_at'] == null ? null : DateTime.parse(json['completed_at'] as String),
  );

  CorrectiveAction copyWith({String? status}) => CorrectiveAction(
    id: id, complaintId: complaintId, title: title, owner: owner, dueDate: dueDate,
    status: status ?? this.status, completedAt: status == 'Completed' ? DateTime.now() : null,
  );
}

class ComplaintEvent {
  final int id;
  final int complaintId;
  final String eventType;
  final String message;
  final String actor;
  final DateTime createdAt;

  const ComplaintEvent({required this.id, required this.complaintId, required this.eventType,
    required this.message, required this.actor, required this.createdAt});

  factory ComplaintEvent.fromJson(Map<String, dynamic> json) => ComplaintEvent(
    id: (json['id'] as num).toInt(),
    complaintId: (json['complaint_id'] as num).toInt(),
    eventType: json['event_type'] as String,
    message: json['message'] as String,
    actor: json['actor'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
