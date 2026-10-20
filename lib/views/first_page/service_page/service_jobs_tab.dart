import 'package:e_auction/models/service_job.dart';
import 'package:e_auction/models/technician_profile.dart';
import 'package:e_auction/services/service_job_store.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:e_auction/views/first_page/service_page/service_job_detail_page.dart';
import 'package:e_auction/views/first_page/service_page/service_job_form_page.dart';
import 'package:flutter/material.dart';

class ServiceJobsTab extends StatefulWidget {
  final TechnicianProfile? mine;

  const ServiceJobsTab({super.key, this.mine});

  @override
  State<ServiceJobsTab> createState() => _ServiceJobsTabState();
}

class _ServiceJobsTabState extends State<ServiceJobsTab> {
  List<ServiceJob> _jobs = [];
  String? _ownerId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final ownerId = await UserDataManager.getID();
    final jobs = await ServiceJobStore.loadJobs();
    if (!mounted) return;
    setState(() {
      _ownerId = ownerId;
      _jobs = jobs;
      _isLoading = false;
    });
  }

  List<ServiceJob> get _mine =>
      _jobs.where((job) => job.ownerId == _ownerId).toList();

  List<ServiceJob> get _openForMe {
    final mine = widget.mine;
    if (mine == null || mine.status != 1) return [];
    return _jobs.where((job) {
      return job.isOpen &&
          job.ownerId != mine.ownerId &&
          mine.skills.contains(job.skill);
    }).toList();
  }

  Future<void> _create() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ServiceJobFormPage()),
    );
    if (saved == true) _load();
  }

  Future<void> _open(ServiceJob job) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceJobDetailPage(job: job, mine: widget.mine),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final mineJobs = _mine;
    final openJobs = _openForMe;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        FilledButton.icon(
          onPressed: _create,
          style: FilledButton.styleFrom(
            backgroundColor: context.customTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.add),
          label: const Text('ประกาศจ้างช่าง'),
        ),
        const SizedBox(height: 16),
        const Text('ประกาศของฉัน', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (mineJobs.isEmpty)
          const Text(
            'ยังไม่มีประกาศ',
            style: TextStyle(color: Color(0xFF8A8A8A)),
          ),
        for (final job in mineJobs) _card(job),
        const SizedBox(height: 16),
        const Text(
          'งานที่เสนอราคาได้',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (widget.mine == null || widget.mine!.status != 1)
          const Text(
            'ช่างที่ผ่านการตรวจแล้วจะเห็นงานที่ตรงทักษะที่นี่',
            style: TextStyle(color: Color(0xFF8A8A8A)),
          )
        else if (openJobs.isEmpty)
          const Text(
            'ยังไม่มีงานที่ตรงทักษะ',
            style: TextStyle(color: Color(0xFF8A8A8A)),
          ),
        for (final job in openJobs) _card(job),
      ],
    );
  }

  Widget _card(ServiceJob job) {
    final budget = job.budget;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          title: Text(job.title),
          subtitle: Text(
            '${job.skill} · ${job.area}\n${job.statusLabel}'
            '${budget == null ? '' : ' · งบ ${Format.formatCurrency(budget)}'}',
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(job),
        ),
      ),
    );
  }
}
