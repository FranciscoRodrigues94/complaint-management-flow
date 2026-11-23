import 'package:flutter/material.dart';
import 'models/complaint.dart';
import 'pages/about_page.dart';
import 'pages/actions_page.dart';
import 'pages/complaint_detail_page.dart';
import 'pages/complaints_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/new_complaint_page.dart';
import 'services/complaint_repository.dart';
import 'widgets/app_widgets.dart';

const useApi = bool.fromEnvironment('USE_API', defaultValue: false);
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');

void main() => runApp(const ComplaintManagementApp());

class ComplaintManagementApp extends StatelessWidget {
  const ComplaintManagementApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Complaint Management Flow',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: blue),
      scaffoldBackgroundColor: canvas, fontFamily: 'Arial'),
    home: const AppHome(),
  );
}

class AppHome extends StatefulWidget {
  const AppHome({super.key});
  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  late final ComplaintRepository _repository = useApi ? ApiComplaintRepository(apiBaseUrl) : DemoComplaintRepository();
  List<Complaint> _complaints = [];
  List<CorrectiveAction> _actions = [];
  List<ComplaintEvent> _events = [];
  bool _loading = true;
  String? _error;
  int _page = 0;
  int? _selectedComplaintId;

  @override
  void initState() {
    super.initState();
    _reload(showSpinner: true);
  }

  Future<void> _reload({bool showSpinner = false}) async {
    if (showSpinner) setState(() { _loading = true; _error = null; });
    try {
      final complaints = await _repository.listComplaints();
      final actions = await _repository.listActions();
      final events = _selectedComplaintId == null ? <ComplaintEvent>[] : await _repository.listEvents(_selectedComplaintId!);
      if (!mounted) return;
      setState(() {
        _complaints = complaints;
        _actions = actions;
        _events = events;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString(); _loading = false; });
    }
  }

  void _navigate(int page) => setState(() { _page = page; _selectedComplaintId = null; _events = []; });

  Future<void> _openComplaint(int id) async {
    setState(() { _page = 5; _selectedComplaintId = id; _events = []; });
    await _reload();
  }

  Future<void> _create(Map<String, dynamic> data) async {
    final complaint = await _repository.createComplaint(data);
    _selectedComplaintId = complaint.id;
    _page = 5;
    await _reload();
    if (_error != null) throw StateError(_error!);
  }

  Future<void> _mutate(Future<void> Function() operation) async {
    await operation();
    await _reload();
    if (_error != null) throw StateError(_error!);
  }

  @override
  Widget build(BuildContext context) {
    const names = ['Dashboard', 'Complaints', 'New complaint', 'Corrective actions', 'About'];
    const icons = [Icons.dashboard_outlined, Icons.assignment_outlined,
      Icons.add_circle_outline, Icons.checklist_outlined, Icons.info_outline];
    final selected = _complaints.where((c) => c.id == _selectedComplaintId).firstOrNull;
    return Scaffold(body: LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 960;
      return Row(children: [
        Container(width: compact ? 74 : 235, color: navy, child: SafeArea(child: Column(children: [
          Padding(padding: EdgeInsets.fromLTRB(compact ? 18 : 20, 26, 16, 28), child: Row(children: [
            const Icon(Icons.fact_check_outlined, color: Colors.white, size: 31),
            if (!compact) const SizedBox(width: 12),
            if (!compact) const Expanded(child: Text('Complaint\nManagement Flow',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
          ])),
          for (var i = 0; i < names.length; i++)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Tooltip(message: names[i], child: Material(
                color: _page == i || (_page == 5 && i == 1) ? const Color(0xFF315A8A) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                child: ListTile(dense: true, contentPadding: EdgeInsets.symmetric(horizontal: compact ? 16 : 12),
                  leading: Icon(icons[i], color: Colors.white, size: 21),
                  title: compact ? null : Text(names[i], style: const TextStyle(color: Colors.white, fontSize: 13)),
                  onTap: () => _navigate(i),
                ),
              ))),
          const Spacer(),
          if (!compact) Padding(padding: const EdgeInsets.all(18),
            child: Text(useApi ? 'LOCAL API MODE · PostgreSQL' : 'DEMO MODE · FICTIONAL DATA',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10))),
        ]))),
        Expanded(child: Column(children: [
          Container(height: 62, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              const Icon(Icons.layers_outlined, color: blue),
              const SizedBox(width: 9),
              const Expanded(child: Text('Quality operations', style: TextStyle(fontWeight: FontWeight.w600, color: ink))),
              if (constraints.maxWidth > 700) Padding(padding: const EdgeInsets.only(right: 10), child: StatusChip(useApi ? 'Local API' : 'Demo data')),
              IconButton(tooltip: 'Refresh data', onPressed: () => _reload(showSpinner: true), icon: const Icon(Icons.refresh)),
            ])),
          Expanded(child: Padding(padding: const EdgeInsets.all(22),
            child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_outlined, size: 48, color: muted),
                  const SizedBox(height: 12),
                  Text('Unable to load data: $_error', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () => _reload(showSpinner: true), child: const Text('Retry')),
                ])) : switch (_page) {
                0 => DashboardPage(complaints: _complaints, actions: _actions,
                  onOpenComplaints: () => _navigate(1), onOpenComplaint: _openComplaint),
                1 => ComplaintsPage(complaints: _complaints, onNewComplaint: () => _navigate(2), onOpenComplaint: _openComplaint),
                2 => NewComplaintPage(onCreate: _create, onCancel: () => _navigate(1)),
                3 => ActionsPage(actions: _actions, complaints: _complaints,
                  onOpenComplaint: _openComplaint,
                  onChangeStatus: (id, status) => _mutate(() async { await _repository.updateAction(id, status, 'Demo operator'); })),
                4 => const AboutPage(),
                5 when selected != null => ComplaintDetailPage(
                  key: ValueKey(selected.id), complaint: selected,
                  actions: _actions.where((a) => a.complaintId == selected.id).toList(),
                  events: _events, canExportPdf: _repository.supportsPdfExport,
                  onBack: () => _navigate(1),
                  onSaveContainment: (notes, actor) => _mutate(() async { await _repository.updateContainment(selected.id, notes, actor); }),
                  onSaveInvestigation: (cause, actor) => _mutate(() async { await _repository.updateInvestigation(selected.id, cause, actor); }),
                  onSaveVerification: (result, notes, reviewer, actor) => _mutate(() async {
                    await _repository.updateVerification(selected.id, result, notes, reviewer, actor);
                  }),
                  onTransition: (status, actor) => _mutate(() async { await _repository.transition(selected.id, status, actor); }),
                  onAddAction: (title, owner, date, actor) => _mutate(() async {
                    await _repository.createAction(selected.id, title, owner, date, actor);
                  }),
                  onUpdateAction: (id, status, actor) => _mutate(() async { await _repository.updateAction(id, status, actor); }),
                  onExportPdf: () => _repository.exportReport(selected.id, selected.reference),
                ),
                _ => const Center(child: Text('Complaint not found. Return to the register.')),
              },
          )),
        ])),
      ]);
    }));
  }
}
