import 'package:flutter/material.dart';

const navy = Color(0xFF172554);
const blue = Color(0xFF2563EB);
const canvas = Color(0xFFF3F6FB);
const ink = Color(0xFF1E293B);
const muted = Color(0xFF64748B);

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const SectionCard({super.key, required this.title, required this.child, this.trailing});

  
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: navy))),
          ?trailing,
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    ),
  );
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'Open' => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      'In Progress' => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'Pending Verification' => (const Color(0xFFEDE9FE), const Color(0xFF6D28D9)),
      'Closed' || 'Completed' || 'Effective' => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      'High' || 'Ineffective' => (const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF475569)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class PageTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const PageTitle({super.key, required this.title, required this.subtitle, this.action});

  
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: ink))),
      ?action,
    ]),
    const SizedBox(height: 5),
    Text(subtitle, style: const TextStyle(fontSize: 13, color: muted)),
    const SizedBox(height: 20),
  ]);

}

String formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String formatDateTime(DateTime date) => '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

void showNotice(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message),
    backgroundColor: error ? const Color(0xFFB91C1C) : navy));
}

InputDecoration fieldDecoration(String label, {String? hint}) => InputDecoration(
  labelText: label, hintText: hint, border: const OutlineInputBorder(),
  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
);
