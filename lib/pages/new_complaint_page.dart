import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart';

class NewComplaintPage extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onCreate;
  final VoidCallback onCancel;
  const NewComplaintPage({super.key, required this.onCreate, required this.onCancel});
  @override
  State<NewComplaintPage> createState() => _NewComplaintPageState();
}

class _NewComplaintPageState extends State<NewComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _customer = TextEditingController();
  final _itemCode = TextEditingController();
  final _description = TextEditingController();
  final _reporter = TextEditingController(text: 'Alex Morgan');
  final _assignee = TextEditingController(text: 'Jordan Lee');
  final _affected = TextEditingController(text: '100');
  final _rejected = TextEditingController(text: '0');
  final _estimatedCost = TextEditingController();
  String _category = 'Visual defect';
  String _severity = 'Medium';
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [_title, _customer, _itemCode, _description, _reporter, _assignee, _affected, _rejected, _estimatedCost]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().length < 2 ? 'Please enter at least 2 characters.' : null;
  String? _titleValidator(String? value) => value == null || value.trim().length < 3 ? 'Enter at least 3 characters.' : null;
  String? _descriptionValidator(String? value) => value == null || value.trim().length < 5 ? 'Enter at least 5 characters.' : null;
  String? _positive(String? value) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < 1 ? 'Enter a positive whole number.' : null;
  }
  String? _nonNegative(String? value) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < 0 ? 'Enter zero or a positive whole number.' : null;
  }
  String? _money(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final amount = double.tryParse(value.trim().replaceAll(',', '.'));
    return amount == null || !amount.isFinite || amount < 0 ? 'Enter a valid, non-negative amount.' : null;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (int.parse(_rejected.text) > int.parse(_affected.text)) {
      showNotice(context, 'Rejected quantity must not exceed affected quantity.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onCreate({
        'title': _title.text.trim(), 'customer': _customer.text.trim(), 'item_code': _itemCode.text.trim(),
        'description': _description.text.trim(), 'category': _category, 'severity': _severity,
        'reporter': _reporter.text.trim(), 'assigned_to': _assignee.text.trim(),
        'affected_quantity': int.parse(_affected.text), 'rejected_quantity': int.parse(_rejected.text),
        'estimated_cost': _estimatedCost.text.trim().isEmpty ? null : double.parse(_estimatedCost.text.trim().replaceAll(',', '.')),
      });
    } catch (error) {
      if (mounted) showNotice(context, 'Could not save: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(children: [
    PageTitle(title: 'Register a complaint', subtitle: 'Create a fictional quality case with traceable ownership.'),
    SectionCard(title: 'Incident information', child: Form(key: _formKey, child: Column(children: [
      TextFormField(controller: _title, maxLength: 160, decoration: fieldDecoration('Incident title *'), validator: _titleValidator),
      const SizedBox(height: 12),
      _pair(
        TextFormField(controller: _customer, maxLength: 120, decoration: fieldDecoration('Customer or supplier *'), validator: _required),
        TextFormField(controller: _itemCode, maxLength: 60, decoration: fieldDecoration('Item / part code *'), validator: _required),
      ),
      const SizedBox(height: 12),
      _pair(
        DropdownButtonFormField<String>(initialValue: _category, isExpanded: true, decoration: fieldDecoration('Defect category'),
          items: ['Visual defect', 'Dimensional', 'Packaging', 'Assembly', 'Missing parts', 'Contamination', 'Documentation', 'Functional', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (value) => setState(() => _category = value ?? _category)),
        DropdownButtonFormField<String>(initialValue: _severity, isExpanded: true, decoration: fieldDecoration('Severity'),
          items: ['Low', 'Medium', 'High'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (value) => setState(() => _severity = value ?? _severity)),
      ),
      const SizedBox(height: 12),
      TextFormField(controller: _description, decoration: fieldDecoration('Problem description *'), maxLines: 4, maxLength: 3000, validator: _descriptionValidator),
    ]))),
    const SizedBox(height: 12),
    SectionCard(title: 'Ownership and scope', child: Column(children: [
      _pair(
        TextFormField(controller: _reporter, maxLength: 100, decoration: fieldDecoration('Reported by *'), validator: _required),
        TextFormField(controller: _assignee, maxLength: 100, decoration: fieldDecoration('Assigned to *'), validator: _required),
      ),
      const SizedBox(height: 12),
      _pair(
        TextFormField(controller: _affected, keyboardType: TextInputType.number, decoration: fieldDecoration('Affected quantity *'), validator: _positive),
        TextFormField(controller: _rejected, keyboardType: TextInputType.number, decoration: fieldDecoration('Rejected quantity *'), validator: _nonNegative),
      ),
      const SizedBox(height: 12),
      const Align(alignment: Alignment.centerLeft, child: Text('The workflow starts as Open. Containment and investigation follow after registration.', style: TextStyle(color: muted, fontSize: 12))),
    ])),
    const SizedBox(height: 12),
    SectionCard(title: 'Financial impact', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 320, child: TextFormField(controller: _estimatedCost, keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: fieldDecoration('Estimated financial impact (€)'), validator: _money)),
      const SizedBox(height: 8),
      const Text('Optional initial estimate. Record scrap, rework and inspection costs later in complaint details.',
        style: TextStyle(color: muted, fontSize: 12)),
    ])),
    const SizedBox(height: 20),
    Wrap(spacing: 10, runSpacing: 10, children: [
      FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Create complaint')),
      OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel')),
    ]),
  ]);

  Widget _pair(Widget left, Widget right) => LayoutBuilder(builder: (context, constraints) {
    if (constraints.maxWidth < 680) return Column(children: [left, const SizedBox(height: 12), right]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 12), Expanded(child: right)]);
  });
}
