import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(children: [
    PageTitle(title: 'About Complaint Management Flow',
      subtitle: 'A standalone quality complaint workflow created for a software development portfolio.'),
    SectionCard(title: 'Purpose', child: const Text(
      'Quality teams need more than a spreadsheet of complaints. This demo shows how an industrial incident can be '
      'registered, contained, investigated, resolved through accountable actions, and closed after effectiveness verification. '
      'All organizations, parts, employees and incidents shown here are fictional.',
      style: TextStyle(height: 1.6))),
    const SizedBox(height: 14),
    SectionCard(title: 'Key capabilities', child: Column(children: [
      _feature(Icons.workspaces_outline, 'Controlled workflow', 'Open → In Progress → Pending Verification → Closed, with server-side guards.'),
      _feature(Icons.assignment_turned_in_outlined, 'Corrective actions', 'Named owners, due dates, completion and overdue visibility.'),
      _feature(Icons.analytics_outlined, 'Operational overview', 'Complaint status, defect categories, closure rate and action alerts.'),
      _feature(Icons.history_outlined, 'Change history', 'Actor-labelled events for case updates and status transitions.'),
      _feature(Icons.picture_as_pdf_outlined, 'PDF report', 'Export a structured complaint report when running against the local API.'),
    ])),
    const SizedBox(height: 14),
    SectionCard(title: 'Technology and environments', child: Column(children: [
      _feature(Icons.desktop_windows_outlined, 'Desktop frontend', 'Flutter and Dart. No external Flutter packages required.'),
      _feature(Icons.api_outlined, 'REST backend', 'Python FastAPI, Pydantic validation and PDF generation with ReportLab.'),
      _feature(Icons.storage_outlined, 'Database', 'PostgreSQL with relationships, constraints and transactional changes.'),
      _feature(Icons.science_outlined, 'Two running modes', 'In-memory demo mode; persistent local API mode using PostgreSQL.'),
    ])),
    const SizedBox(height: 14),
    SectionCard(title: 'Security and production scope', child: const Text(
      'This project is intentionally a local portfolio demonstration. It does not include user authentication, access control, '
      'TLS termination or deployment hardening. Do not expose the API to public or corporate networks without implementing '
      'these controls. Names in the activity history are manually declared, not authenticated identities.',
      style: TextStyle(height: 1.6))),
    const SizedBox(height: 22),
    const Center(child: Text('Independent demonstration · No company branding or production data', style: TextStyle(color: muted, fontSize: 12))),
  ]);

  Widget _feature(IconData icon, String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 23, color: blue),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 3),
        Text(description, style: const TextStyle(color: muted, fontSize: 12)),
      ])),
    ]),
  );
}
