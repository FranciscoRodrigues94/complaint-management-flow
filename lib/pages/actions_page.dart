import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../widgets/app_widgets.dart';

class ActionsPage extends StatefulWidget {
  final List<CorrectiveAction> actions;
  final List<Complaint> complaints;
  final void Function(int) onOpenComplaint;
  final Future<void> Function(int, String) onChangeStatus;
  const ActionsPage({super.key, required this.actions, required this.complaints,
    required this.onOpenComplaint, required this.onChangeStatus});
  @override
  State<ActionsPage> createState() => _ActionsPageState();
}

class _ActionsPageState extends State<ActionsPage> {
  String _filter = 'All';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.actions.where((a) => _filter == 'All' || a.status == _filter).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final overdue = widget.actions.where((a) => a.status != 'Completed' &&
      DateUtils.dateOnly(a.dueDate).isBefore(DateUtils.dateOnly(DateTime.now()))).length;
    return ListView(children: [
      PageTitle(title: 'Corrective actions', subtitle: 'Assign ownership, follow deadlines and track completion.'),
      SectionCard(title: 'Action tracker', trailing: Text('$overdue overdue', style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w600)), child: Column(children: [
        Align(alignment: Alignment.centerLeft, child: SizedBox(width: 220, child: DropdownButtonFormField<String>(
          initialValue: _filter, decoration: fieldDecoration('Action status'),
          items: ['All', 'Open', 'In Progress', 'Completed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (value) => setState(() => _filter = value ?? 'All'),
        ))),
        const SizedBox(height: 16),
        if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No actions found.')),
        for (final action in filtered)
          Builder(builder: (context) {
            final complaint = widget.complaints.where((c) => c.id == action.complaintId).firstOrNull;
            final locked = complaint == null || complaint.status == 'Closed' || complaint.status == 'Pending Verification';
            return Card(color: const Color(0xFFF8FAFC), elevation: 0, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(children: [
                Expanded(child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(action.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${complaint?.reference ?? 'Case unavailable'} · ${action.owner} · Due ${formatDate(action.dueDate)}'),
                  onTap: complaint == null ? null : () => widget.onOpenComplaint(action.complaintId),
                )),
                if (action.status != 'Completed' && DateUtils.dateOnly(action.dueDate).isBefore(DateUtils.dateOnly(DateTime.now())))
                  const Tooltip(message: 'Past due date', child: Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C))),
                const SizedBox(width: 8),
                SizedBox(width: 155, child: DropdownButton<String>(value: action.status, isExpanded: true, underline: const SizedBox(),
                  items: ['Open', 'In Progress', 'Completed'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: locked ? null : (value) async {
                    if (value == null || value == action.status) return;
                    try { await widget.onChangeStatus(action.id, value); }
                    catch (error) { if (context.mounted) showNotice(context, '$error', error: true); }
                  },
                )),
                IconButton(tooltip: 'Open complaint', onPressed: complaint == null ? null : () => widget.onOpenComplaint(action.complaintId), icon: const Icon(Icons.chevron_right)),
              ]),
            ));
          }),
      ])),
    ]);
  }
}
