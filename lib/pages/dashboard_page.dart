import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../widgets/app_widgets.dart';

class DashboardPage extends StatelessWidget {
  final List<Complaint> complaints;
  final List<CorrectiveAction> actions;
  final VoidCallback onOpenComplaints;
  final void Function(int) onOpenComplaint;
  const DashboardPage({super.key, required this.complaints, required this.actions,
    required this.onOpenComplaints, required this.onOpenComplaint});

  @override
  Widget build(BuildContext context) {
    final closed = complaints.where((c) => c.status == 'Closed').length;
    final active = complaints.where((c) => c.status != 'Closed').length;
    final high = complaints.where((c) => c.status != 'Closed' && c.severity == 'High').length;
    final overdue = actions.where((a) => a.status != 'Completed' &&
      DateUtils.dateOnly(a.dueDate).isBefore(DateUtils.dateOnly(DateTime.now()))).length;
    final completedActions = actions.where((a) => a.status == 'Completed').length;
    final actionCompletionRate = actions.isEmpty ? 0 : (completedActions / actions.length * 100).round();
    final costCases = complaints.where((c) => c.hasRecordedCosts).toList();
    final totalCost = costCases.fold<double>(0, (sum, c) => sum + c.totalQualityCost);
    final averageCost = costCases.isEmpty ? 0.0 : totalCost / costCases.length;
    final recent = [...complaints]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final categoryCounts = <String, int>{};
    final categoryCosts = <String, double>{};
    final monthlyCounts = <DateTime, int>{};
    for (final complaint in complaints) {
      final category = complaint.category.trim().isEmpty ? 'Other' : complaint.category.trim();
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      if (complaint.hasRecordedCosts) categoryCosts[category] = (categoryCosts[category] ?? 0) + complaint.totalQualityCost;
      final month = DateTime(complaint.createdAt.year, complaint.createdAt.month);
      monthlyCounts[month] = (monthlyCounts[month] ?? 0) + 1;
    }
    final sortedCategories = categoryCounts.entries.toList()..sort((a, b) {
      final comparison = b.value.compareTo(a.value);
      return comparison != 0 ? comparison : a.key.compareTo(b.key);
    });
    final sortedCosts = categoryCosts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final months = monthlyCounts.keys.toList()..sort();
    final highestMonthly = monthlyCounts.values.fold<int>(0, (highest, value) => value > highest ? value : highest);
    final highestCost = sortedCosts.isEmpty ? 0.0 : sortedCosts.first.value;
    return ListView(children: [
      PageTitle(title: 'Quality dashboard', subtitle: 'Quality performance and financial impact from your complaint register.',
        action: OutlinedButton.icon(onPressed: onOpenComplaints, icon: const Icon(Icons.list), label: const Text('Complaint register'))),
      LayoutBuilder(builder: (context, c) => Wrap(spacing: 12, runSpacing: 12, children: [
        _metric('Total cases', '${complaints.length}', Icons.folder_outlined, c.maxWidth),
        _metric('Active cases', '$active', Icons.pending_actions_outlined, c.maxWidth),
        _metric('Closure rate', complaints.isEmpty ? '0%' : '${(closed / complaints.length * 100).round()}%', Icons.task_alt_outlined, c.maxWidth),
        _metric('Recorded quality costs', costCases.isEmpty ? 'No data' : _euro(totalCost), Icons.euro_outlined, c.maxWidth),
        _metric('Overdue actions', '$overdue', Icons.schedule, c.maxWidth),
        _metric('Action completion', '$actionCompletionRate%', Icons.fact_check_outlined, c.maxWidth),
        _metric('High severity active', '$high', Icons.priority_high, c.maxWidth),
        _metric('Avg. recorded cost', costCases.isEmpty ? 'No data' : _euro(averageCost), Icons.receipt_long_outlined, c.maxWidth),
      ])),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, c) {
        final a = SectionCard(title: 'Cases by status', child: Column(children: [
          for (final status in ['Open', 'In Progress', 'Pending Verification', 'Closed'])
            _progress(status, complaints.where((item) => item.status == status).length, complaints.length, blue),
        ]));
        final b = SectionCard(title: 'Defect categories', child: Column(children: [
          for (final category in sortedCategories)
            _progress(category.key, category.value, complaints.length, const Color(0xFF64748B)),
          if (sortedCategories.isEmpty) const Text('No defect categories available.'),
        ]));
        if (c.maxWidth < 780) return Column(children: [a, const SizedBox(height: 12), b]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]);
      }),
      const SizedBox(height: 14),
      LayoutBuilder(builder: (context, c) {
        final a = SectionCard(title: 'Monthly complaint trend', child: Column(children: [
          for (final month in months)
            _progress('${_monthName(month.month)} ${month.year}', monthlyCounts[month]!, highestMonthly, blue),
          if (months.isEmpty) const Text('No monthly data available.'),
        ]));
        final b = SectionCard(title: 'Quality costs by category', child: Column(children: [
          for (final category in sortedCosts)
            _costBar(category.key, category.value, highestCost),
          if (sortedCosts.isEmpty) const Text('No actual costs recorded yet.'),
          const SizedBox(height: 6),
          Text('Recorded costs: ${costCases.length} / ${complaints.length} cases', style: const TextStyle(color: muted, fontSize: 11)),
        ]));
        if (c.maxWidth < 780) return Column(children: [a, const SizedBox(height: 12), b]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]);
      }),
      const SizedBox(height: 14),
      SectionCard(title: 'Items needing attention', child: Wrap(spacing: 16, runSpacing: 12, children: [
        _insight(Icons.priority_high, '$high high-severity active cases', 'Review priority complaints.'),
        _insight(Icons.assignment_late_outlined, '$overdue overdue corrective actions', 'Follow up on missed deadlines.'),
        _insight(Icons.fact_check_outlined, '${complaints.where((c) => c.status == 'Pending Verification').length} awaiting verification', 'Review effectiveness evidence.'),
      ])),
      const SizedBox(height: 14),
      SectionCard(title: 'Recent complaints', trailing: TextButton(onPressed: onOpenComplaints, child: const Text('View all')),
        child: Column(children: [
          for (final complaint in recent.take(6))
            ListTile(contentPadding: EdgeInsets.zero, onTap: () => onOpenComplaint(complaint.id),
              title: Text(complaint.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${complaint.reference} · ${complaint.customer} · ${formatDate(complaint.createdAt)}'),
              trailing: StatusChip(complaint.status)),
          if (recent.isEmpty) const Text('No complaints have been registered yet.'),
        ])),
    ]);
  }

  String _euro(double amount) => '€${amount.toStringAsFixed(2)}';
  String _monthName(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];

  Widget _metric(String title, String value, IconData icon, double width) {
    final itemWidth = width < 560 ? width : width < 1050 ? (width - 12) / 2 : (width - 36) / 4;
    return SizedBox(width: itemWidth, child: Card(elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
        Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: blue)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, color: ink, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: muted)),
        ])),
      ]))));
  }

  Widget _progress(String label, int value, int total, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 14), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text('$value / $total', style: const TextStyle(color: muted, fontSize: 12)),
      ]),
      const SizedBox(height: 7),
      LinearProgressIndicator(value: total == 0 ? 0 : value / total, minHeight: 7, color: color,
        backgroundColor: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(5)),
    ]));

  Widget _costBar(String label, double cost, double maximum) => Padding(
    padding: const EdgeInsets.only(bottom: 14), child: Column(children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text(_euro(cost), style: const TextStyle(color: muted, fontSize: 12)),
      ]),
      const SizedBox(height: 7),
      LinearProgressIndicator(value: maximum <= 0 ? 0 : cost / maximum, minHeight: 7,
        color: const Color(0xFF64748B), backgroundColor: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(5)),
    ]));

  Widget _insight(IconData icon, String title, String subtitle) => SizedBox(width: 260, child: Row(
    children: [Icon(icon, color: blue), const SizedBox(width: 9), Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 11)),
      ]))],
  ));
}
