
import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../widgets/app_widgets.dart';

class ComplaintsPage extends StatefulWidget {
  final List<Complaint> complaints;
  final VoidCallback onNewComplaint;
  final void Function(int) onOpenComplaint;
  const ComplaintsPage({super.key, required this.complaints, required this.onNewComplaint, required this.onOpenComplaint});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  String _search = '';
  String _status = 'All';
  String _severity = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.complaints.where((c) {
      final text = '${c.reference} ${c.title} ${c.customer} ${c.itemCode} ${c.assignedTo}'.toLowerCase();
      return text.contains(_search.toLowerCase()) && (_status == 'All' || c.status == _status) &&
          (_severity == 'All' || c.severity == _severity);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(children: [
      PageTitle(title: 'Complaint register', subtitle: 'Track the full lifecycle of each quality incident.',
        action: FilledButton.icon(onPressed: widget.onNewComplaint, icon: const Icon(Icons.add), label: const Text('New complaint'))),
      SectionCard(title: '${filtered.length} complaints', child: Column(children: [
        LayoutBuilder(builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final searchWidth = availableWidth < 320 ? availableWidth : 320.0;
          final statusWidth = availableWidth < 240 ? availableWidth : 240.0;
          final severityWidth = availableWidth < 150 ? availableWidth : 150.0;

          return Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(width: searchWidth, child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: fieldDecoration('Search reference, customer, item or owner').copyWith(
                prefixIcon: const Icon(Icons.search)),
            )),
            SizedBox(width: statusWidth, child: DropdownButtonFormField<String>(
              initialValue: _status,
              isExpanded: true,
              decoration: fieldDecoration('Status'),
              items: ['All', 'Open', 'In Progress', 'Pending Verification', 'Closed']
                  .map((item) => DropdownMenuItem(value: item,
                    child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (value) => setState(() => _status = value ?? 'All'),
            )),
            SizedBox(width: severityWidth, child: DropdownButtonFormField<String>(
              initialValue: _severity,
              isExpanded: true,
              decoration: fieldDecoration('Severity'),
              items: ['All', 'Low', 'Medium', 'High']
                  .map((item) => DropdownMenuItem(value: item,
                    child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (value) => setState(() => _severity = value ?? 'All'),
            )),
          ]);
        }),
        const SizedBox(height: 16),
        if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No complaints match these filters.')),
        for (final complaint in filtered)
          Card(elevation: 0, color: const Color(0xFFF8FAFC), child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(backgroundColor: const Color(0xFFE2E8F0), child: Icon(
              complaint.severity == 'High' ? Icons.priority_high : Icons.description_outlined, color: navy)),
            title: Text(complaint.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${complaint.reference}  ·  ${complaint.customer}  ·  ${complaint.itemCode}\nAssigned to ${complaint.assignedTo}'),
            isThreeLine: true,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [StatusChip(complaint.status), const SizedBox(width: 10), const Icon(Icons.chevron_right)]),
            onTap: () => widget.onOpenComplaint(complaint.id),
          )),
      ])),
    ]);
  }
}
