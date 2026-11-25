import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../widgets/app_widgets.dart';

class ComplaintDetailPage extends StatefulWidget {
  final Complaint complaint;
  final List<CorrectiveAction> actions;
  final List<ComplaintEvent> events;
  final bool canExportPdf;
  final VoidCallback onBack;
  final Future<void> Function(String, String) onSaveContainment;
  final Future<void> Function(String, String) onSaveInvestigation;
  final Future<void> Function(String, String, String, String) onSaveVerification;
  final Future<void> Function(String, String) onTransition;
  final Future<void> Function(String, String, DateTime, String) onAddAction;
  final Future<void> Function(int, String, String) onUpdateAction;
  final Future<String> Function() onExportPdf;
  final Future<void> Function(Map<String, double>, String)? onSaveCosts;

  const ComplaintDetailPage({super.key, required this.complaint, required this.actions,
    required this.events, required this.canExportPdf, required this.onBack,
    required this.onSaveContainment, required this.onSaveInvestigation,
    required this.onSaveVerification, required this.onTransition, required this.onAddAction,
    required this.onUpdateAction, required this.onExportPdf, this.onSaveCosts});

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  int _tab = 0;
  bool _busy = false;
  late final TextEditingController _actor;
  late final TextEditingController _containment;
  late final TextEditingController _rootCause;
  late final TextEditingController _verificationNotes;
  late final TextEditingController _reviewer;
  late String _verificationResult;
  late final TextEditingController _scrapCost;
  late final TextEditingController _reworkCost;
  late final TextEditingController _inspectionCost;
  late final TextEditingController _otherCost;

  @override
  void initState() {
    super.initState();
    _actor = TextEditingController(text: 'Alex Morgan');
    _containment = TextEditingController(text: widget.complaint.containmentAction);
    _rootCause = TextEditingController(text: widget.complaint.rootCause);
    _verificationNotes = TextEditingController(text: widget.complaint.verificationNotes);
    _reviewer = TextEditingController(text: widget.complaint.verifiedBy);
    _verificationResult = widget.complaint.verificationResult;
    _scrapCost = TextEditingController(text: _costText(widget.complaint.scrapCost));
    _reworkCost = TextEditingController(text: _costText(widget.complaint.reworkCost));
    _inspectionCost = TextEditingController(text: _costText(widget.complaint.inspectionCost));
    _otherCost = TextEditingController(text: _costText(widget.complaint.otherCost));
  }

  @override
  void didUpdateWidget(covariant ComplaintDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.complaint.id != widget.complaint.id) {
      _containment.text = widget.complaint.containmentAction;
      _rootCause.text = widget.complaint.rootCause;
      _verificationNotes.text = widget.complaint.verificationNotes;
      _reviewer.text = widget.complaint.verifiedBy;
      _verificationResult = widget.complaint.verificationResult;
      _syncCostControllers();
      _tab = 0;
    } else if (oldWidget.complaint != widget.complaint && !_busy) {
      _syncCostControllers();
    }
  }

  String _costText(double? cost) => cost == null ? '' : cost.toStringAsFixed(2);
  void _syncCostControllers() {
    _scrapCost.text = _costText(widget.complaint.scrapCost);
    _reworkCost.text = _costText(widget.complaint.reworkCost);
    _inspectionCost.text = _costText(widget.complaint.inspectionCost);
    _otherCost.text = _costText(widget.complaint.otherCost);
  }

  @override
  void dispose() {
    for (final controller in [_actor, _containment, _rootCause, _verificationNotes, _reviewer, _scrapCost, _reworkCost, _inspectionCost, _otherCost]) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _actorName => _actor.text.trim();
  bool get _closed => widget.complaint.status == 'Closed';

  Future<void> _perform(Future<void> Function() action, String? success) async {
    if (_busy) return;
    if (_actorName.length < 2) {
      showNotice(context, 'Enter your name before recording changes.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && success != null) showNotice(context, success);
    } catch (error) {
      if (mounted) showNotice(context, '$error', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final progress = switch (complaint.status) {
      'Open' => 0.2, 'In Progress' => 0.5, 'Pending Verification' => 0.8, _ => 1.0,
    };
    final tabs = ['Overview', 'Containment', 'Investigation & actions', 'Verification', 'Quality costs', 'History'];
    return ListView(children: [
      Row(children: [
        TextButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back), label: const Text('Back to complaints')),
        const Spacer(),
        if (widget.canExportPdf) OutlinedButton.icon(
          onPressed: _busy ? null : () => _perform(() async {
            final path = await widget.onExportPdf();
            if (!context.mounted) return;
            showNotice(context, 'PDF saved to $path');
          }, null),
          icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Export PDF'),
        ),
      ]),
      const SizedBox(height: 8),
      PageTitle(title: complaint.title, subtitle: '${complaint.reference} · ${complaint.customer} · Registered ${formatDate(complaint.createdAt)}',
        action: StatusChip(complaint.status)),
      SectionCard(title: 'Case progress', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LinearProgressIndicator(value: progress, minHeight: 9, color: blue, backgroundColor: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(6)),
        const SizedBox(height: 10),
        Text(switch (complaint.status) {
          'Open' => 'Next: record immediate containment measures.',
          'In Progress' => 'Next: document the cause and complete assigned actions.',
          'Pending Verification' => 'Next: verify that the corrective actions were effective.',
          _ => 'This complaint has been verified and closed.',
        }, style: const TextStyle(color: muted, fontSize: 12)),
      ])),
      const SizedBox(height: 10),
      SectionCard(title: 'Portfolio user identity', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 330, child: TextField(controller: _actor, maxLength: 100, decoration: fieldDecoration('Your name (demo actor)'))),
        const Text('The name above is self-declared for demonstration purposes; this demo has no authentication.', style: TextStyle(color: muted, fontSize: 12)),
      ])),
      const SizedBox(height: 12),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        for (var i = 0; i < tabs.length; i++)
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
            selected: _tab == i, label: Text(tabs[i]),
            onSelected: (_) => setState(() => _tab = i),
          )),
      ])),
      const SizedBox(height: 12),
      switch (_tab) {
        0 => _overview(),
        1 => _containmentPanel(),
        2 => _investigationPanel(),
        3 => _verificationPanel(),
        4 => _costsPanel(),
        _ => _historyPanel(),
      },
      const SizedBox(height: 24),
    ]);
  }

  Widget _overview() {
    final c = widget.complaint;
    return Column(children: [
      SectionCard(title: 'Quality incident', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _info('Reference', c.reference), _info('Status', c.status), _info('Customer', c.customer),
        _info('Item code', c.itemCode), _info('Category', c.category), _info('Severity', c.severity),
        _info('Reported by', c.reporter), _info('Assigned to', c.assignedTo),
        _info('Affected quantity', '${c.affectedQuantity}'), _info('Rejected quantity', '${c.rejectedQuantity}'),
        _info('Estimated impact', c.estimatedCost == null ? 'Not estimated' : '€${c.estimatedCost!.toStringAsFixed(2)}'),
        _info('Recorded quality costs', c.hasRecordedCosts ? '€${c.totalQualityCost.toStringAsFixed(2)}' : 'Not recorded'),
        const SizedBox(height: 12),
        const Text('Problem description', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(c.description),
      ])),
      const SizedBox(height: 12),
      SectionCard(title: 'Workflow checklist', child: Column(children: [
        _check('Containment documented', c.containmentAction.trim().isNotEmpty),
        _check('Root cause documented', c.rootCause.trim().isNotEmpty),
        _check('Corrective actions created', widget.actions.isNotEmpty),
        _check('All actions completed', widget.actions.isNotEmpty && widget.actions.every((a) => a.status == 'Completed')),
        _check('Effectiveness verified', c.verificationResult == 'Effective' && c.verificationNotes.trim().isNotEmpty),
      ])),
    ]);
  }

  Widget _info(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 170, child: Text(label, style: const TextStyle(color: muted))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
    ],
  ));

  Widget _check(String title, bool completed) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
    Icon(completed ? Icons.check_circle : Icons.radio_button_unchecked,
      color: completed ? const Color(0xFF16A34A) : muted, size: 20),
    const SizedBox(width: 10), Text(title),
  ]));

  Widget _containmentPanel() => SectionCard(title: 'Step 1 · Immediate containment', child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Record what was done to prevent further non-conforming product from moving through the process.',
        style: TextStyle(color: muted)),
      const SizedBox(height: 14),
      TextField(controller: _containment, maxLength: 3000, maxLines: 5, readOnly: _closed || widget.complaint.status == 'Pending Verification',
        decoration: fieldDecoration('Containment action', hint: 'e.g. Quarantine affected batch and inspect remaining stock')),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: [
        OutlinedButton.icon(onPressed: _closed || widget.complaint.status == 'Pending Verification' || _busy ? null : () => _perform(
          () => widget.onSaveContainment(_containment.text.trim(), _actorName), 'Containment saved'),
          icon: const Icon(Icons.save_outlined), label: const Text('Save containment')),
        if (widget.complaint.status == 'Open') FilledButton.icon(onPressed: _busy ? null : () => _perform(
          () => widget.onTransition('In Progress', _actorName), 'Investigation started'),
          icon: const Icon(Icons.arrow_forward), label: const Text('Start investigation')),
      ]),
    ],
  ));

  Widget _investigationPanel() {
    final complaint = widget.complaint;
    final locked = _closed || complaint.status == 'Pending Verification';
    return Column(children: [
      SectionCard(title: 'Step 2 · Root cause investigation', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Describe the underlying cause rather than repeating the visible defect.', style: TextStyle(color: muted)),
        const SizedBox(height: 12),
        TextField(controller: _rootCause, maxLength: 3000, maxLines: 5, readOnly: locked,
          decoration: fieldDecoration('Root cause analysis', hint: 'What process or control failed, and why?')),
        OutlinedButton.icon(onPressed: locked || _busy ? null : () => _perform(
          () => widget.onSaveInvestigation(_rootCause.text.trim(), _actorName), 'Root cause saved'),
          icon: const Icon(Icons.save_outlined), label: const Text('Save investigation')),
      ])),
      const SizedBox(height: 12),
      SectionCard(title: 'Step 3 · Corrective action plan', trailing: OutlinedButton.icon(
        onPressed: locked || _busy ? null : _showAddAction,
        icon: const Icon(Icons.add), label: const Text('Add action')),
        child: Column(children: [
          if (widget.actions.isEmpty) const Align(alignment: Alignment.centerLeft, child: Text('No corrective actions yet. Add at least one assigned action.')),
          for (final action in widget.actions)
            Card(elevation: 0, color: canvas, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(action.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${action.owner} · Due ${formatDate(action.dueDate)}', style: const TextStyle(color: muted, fontSize: 12)),
              ])),
              const SizedBox(width: 8),
              SizedBox(width: 145, child: DropdownButton<String>(value: action.status, isExpanded: true, underline: const SizedBox(),
                items: ['Open', 'In Progress', 'Completed'].map((s) => DropdownMenuItem(value: s,
                  child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: locked || _busy ? null : (status) {
                  if (status == null || status == action.status) return;
                  _perform(() => widget.onUpdateAction(action.id, status, _actorName), 'Action updated');
                },
              )),
            ]))),
          if (complaint.status == 'In Progress') ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: FilledButton.icon(
              onPressed: _busy ? null : () => _perform(() => widget.onTransition('Pending Verification', _actorName), 'Submitted for verification'),
              icon: const Icon(Icons.verified_outlined), label: const Text('Submit for verification'))),
          ],
        ])),
    ]);
  }

  Future<void> _showAddAction() async {
    final title = TextEditingController();
    final owner = TextEditingController();
    var dueDate = DateTime.now().add(const Duration(days: 7));
    final result = await showDialog<(String, String, DateTime)>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Add corrective action'),
        content: SizedBox(width: 430, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, maxLength: 200, decoration: fieldDecoration('Action description')),
          const SizedBox(height: 12),
          TextField(controller: owner, maxLength: 100, decoration: fieldDecoration('Responsible person')),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: Text('Due: ${formatDate(dueDate)}')),
            TextButton.icon(onPressed: () async {
              final picked = await showDatePicker(context: dialogContext, initialDate: dueDate,
                firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (picked != null) setDialogState(() => dueDate = picked);
            }, icon: const Icon(Icons.calendar_month), label: const Text('Choose'))]),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            if (title.text.trim().length < 3 || owner.text.trim().length < 2) {
              showNotice(dialogContext, 'Enter an action description and responsible person.', error: true);
              return;
            }
            Navigator.pop(dialogContext, (title.text.trim(), owner.text.trim(), dueDate));
          }, child: const Text('Add action')),
        ],
      ),
    ));
    title.dispose();
    owner.dispose();
    if (result == null || !mounted) return;
    await _perform(() => widget.onAddAction(result.$1, result.$2, result.$3, _actorName), 'Corrective action added');
  }

  Widget _verificationPanel() {
    final status = widget.complaint.status;
    final enabled = status == 'Pending Verification';
    return SectionCard(title: 'Step 4 · Effectiveness verification', child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Confirm whether the corrective actions actually prevented recurrence. Ineffective checks return the case to investigation.',
          style: TextStyle(color: muted)),
        const SizedBox(height: 14),
        SizedBox(width: 230, child: DropdownButtonFormField<String>(initialValue: _verificationResult,
          decoration: fieldDecoration('Verification result'),
          items: ['Not reviewed', 'Effective', 'Ineffective'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: enabled && !_busy ? (value) => setState(() => _verificationResult = value ?? 'Not reviewed') : null,
        )),
        const SizedBox(height: 14),
        TextField(controller: _reviewer, readOnly: !enabled, maxLength: 100, decoration: fieldDecoration('Verified by')),
        const SizedBox(height: 12),
        TextField(controller: _verificationNotes, readOnly: !enabled, maxLength: 3000, maxLines: 4,
          decoration: fieldDecoration('Verification evidence / notes')),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          OutlinedButton.icon(onPressed: enabled && !_busy ? () => _perform(
            () => widget.onSaveVerification(_verificationResult, _verificationNotes.text.trim(), _reviewer.text.trim(), _actorName), 'Verification saved') : null,
            icon: const Icon(Icons.save_outlined), label: const Text('Save verification')),
          if (enabled && widget.complaint.verificationResult == 'Effective')
            FilledButton.icon(onPressed: _busy ? null : () => _perform(
              () => widget.onTransition('Closed', _actorName), 'Complaint closed'),
              icon: const Icon(Icons.check_circle_outline), label: const Text('Close complaint')),
          if (enabled && widget.complaint.verificationResult == 'Ineffective')
            OutlinedButton.icon(onPressed: _busy ? null : () => _perform(
              () => widget.onTransition('In Progress', _actorName), 'Returned to investigation'),
              icon: const Icon(Icons.restart_alt), label: const Text('Return to investigation')),
        ]),
        if (!enabled) const Padding(padding: EdgeInsets.only(top: 10), child: Text(
          'Verification can be edited only while the case is Pending Verification.',
          style: TextStyle(fontSize: 12, color: muted))),
      ],
    ));
  }

  Widget _costsPanel() {
    final c = widget.complaint;
    final editable = !_closed && widget.onSaveCosts != null;
    Widget costField(String label, TextEditingController controller) => TextFormField(
      controller: controller, readOnly: !editable,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: fieldDecoration('$label (€)'),
    );
    return SectionCard(title: 'Cost of Poor Quality', child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c.estimatedCost == null ? 'Initial estimate: not provided' : 'Initial estimate: €${c.estimatedCost!.toStringAsFixed(2)}',
          style: const TextStyle(color: muted)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final fields = [
            costField('Scrap', _scrapCost), costField('Rework', _reworkCost),
            costField('Additional inspection', _inspectionCost), costField('Other', _otherCost),
          ];
          if (constraints.maxWidth < 580) {
            return Column(children: [
              for (final field in fields)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: field),
            ]);
          }
          return Column(children: [
            Row(children: [Expanded(child: fields[0]), const SizedBox(width: 12), Expanded(child: fields[1])]),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: fields[2]), const SizedBox(width: 12), Expanded(child: fields[3])]),
          ]);
        }),
        const SizedBox(height: 12),
        Text(c.hasRecordedCosts ? 'Recorded total: €${c.totalQualityCost.toStringAsFixed(2)}' : 'No actual costs recorded yet.',
          style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (editable) FilledButton.icon(
          onPressed: _busy ? null : () {
            final inputs = [_scrapCost, _reworkCost, _inspectionCost, _otherCost];
            final values = <double>[];
            for (final input in inputs) {
              final raw = input.text.trim();
              final value = raw.isEmpty ? 0.0 : double.tryParse(raw.replaceAll(',', '.'));
              if (value == null || !value.isFinite || value < 0) {
                showNotice(context, 'Enter valid, non-negative cost amounts.', error: true);
                return;
              }
              values.add(value);
            }
            _perform(() => widget.onSaveCosts!({
              'scrap_cost': values[0], 'rework_cost': values[1],
              'inspection_cost': values[2], 'other_cost': values[3],
            }, _actorName), 'Quality costs saved');
          },
          icon: const Icon(Icons.save_outlined), label: const Text('Save costs')),
        if (!_closed && widget.onSaveCosts == null) const Text('Cost editing is not connected in this mode.',
          style: TextStyle(color: muted, fontSize: 12)),
        if (_closed) const Text('Closed complaints are read-only.', style: TextStyle(color: muted, fontSize: 12)),
      ],
    ));
  }

  Widget _historyPanel() => SectionCard(title: 'Activity history', child: Column(children: [
    if (widget.events.isEmpty) const Text('No events yet.'),
    for (final event in widget.events)
      ListTile(contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.history, color: blue),
        title: Text(event.message),
        subtitle: Text('${event.actor} · ${formatDateTime(event.createdAt.toLocal())}'),
      ),
    const Align(alignment: Alignment.centerLeft, child: Text(
      'Audit entries identify the name entered by the demo user, not a verified individual.',
      style: TextStyle(fontSize: 11, color: muted))),
  ]));
}
