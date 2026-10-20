import 'package:e_auction/models/technician_profile.dart';
import 'package:e_auction/views/first_page/service_page/technician_image.dart';
import 'package:e_auction/services/technician_profile_store.dart';
import 'package:e_auction/utils/format.dart';
import 'package:flutter/material.dart';

class TechnicianApprovalPage extends StatefulWidget {
  const TechnicianApprovalPage({super.key});

  @override
  State<TechnicianApprovalPage> createState() => _TechnicianApprovalPageState();
}

class _TechnicianApprovalPageState extends State<TechnicianApprovalPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<TechnicianProfile> _profiles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final profiles = await TechnicianProfileStore.loadAll();
      profiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<TechnicianProfile> _byStatus(int status) {
    return _profiles.where((profile) => profile.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('อนุมัติช่าง'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              tabs: [
                Tab(text: 'รออนุมัติ (${_byStatus(0).length})'),
                Tab(text: 'อนุมัติแล้ว (${_byStatus(1).length})'),
                Tab(text: 'ปฏิเสธ (${_byStatus(2).length})'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : TabBarView(
                    controller: _tabController,
                    children: [
                      _list(_byStatus(0)),
                      _list(_byStatus(1)),
                      _list(_byStatus(2)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<TechnicianProfile> profiles) {
    if (profiles.isEmpty) {
      return const Center(child: Text('ไม่มีรายการในสถานะนี้'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: profiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            title: Text(profile.displayName),
            subtitle: Text(
              '${profile.skills.join(' · ')}\n${profile.serviceArea} · ${Format.formatCurrency(profile.startingPrice)}'
              '${profile.certificatePaths.isEmpty ? '' : ' · มีใบเซอร์'}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final status = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (context) => _TechnicianDetailPage(profile: profile),
                ),
              );
              if (!mounted || status == null) return;
              if (status >= 0 && status <= 2) {
                _tabController.index = status;
              }
              await _load(showSpinner: false);
            },
          ),
        );
      },
    );
  }
}

class _TechnicianDetailPage extends StatefulWidget {
  final TechnicianProfile profile;

  const _TechnicianDetailPage({required this.profile});

  @override
  State<_TechnicianDetailPage> createState() => _TechnicianDetailPageState();
}

class _TechnicianDetailPageState extends State<_TechnicianDetailPage> {
  late TechnicianProfile _profile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _review(int status) async {
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => _ReviewCommentDialog(
        title: status == 1 ? 'อนุมัติช่าง' : 'ปฏิเสธช่าง',
        label: status == 2 ? 'เหตุผล' : 'ความเห็น (ไม่จำเป็น)',
        initialText: _profile.reviewComment ?? '',
      ),
    );
    if (comment == null || !mounted) return;
    if (status == 2 && comment.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรอกเหตุผลก่อนปฏิเสธ')),
      );
      return;
    }

    setState(() => _isSaving = true);
    var leftPage = false;
    try {
      await TechnicianProfileStore.review(
        id: _profile.id,
        status: status,
        comment: comment,
      );
      if (!mounted) return;
      leftPage = true;
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.pop(context, status);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted && !leftPage) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = _profile.reviewComment?.trim();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_profile.displayName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_profile.statusLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('${_profile.skills.join(' · ')} · ${_profile.serviceArea}'),
          Text('ราคาเริ่มต้น ${Format.formatCurrency(_profile.startingPrice)}'),
          if (_profile.ownerPhone.isNotEmpty) Text('โทร ${_profile.ownerPhone}'),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('ความเห็น: $comment'),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _profile.portfolioPaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: technicianImage(
                    _profile.portfolioPaths[index],
                    width: 120,
                    height: 120,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('ใบเซอร์', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _profile.certificatePaths.isEmpty
              ? const Text('ไม่ได้แนบใบเซอร์')
              : SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _profile.certificatePaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: technicianImage(
                          _profile.certificatePaths[index],
                          width: 120,
                          height: 120,
                        ),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 16),
          for (final job in _profile.jobs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(job.title),
              subtitle: job.detail.isEmpty ? null : Text(job.detail),
            ),
          if (_profile.status == 0) ...[
            const SizedBox(height: 16),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _review(2),
                          child: const Text('ปฏิเสธ'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _review(1),
                          child: const Text('อนุมัติ'),
                        ),
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}

class _ReviewCommentDialog extends StatefulWidget {
  final String title;
  final String label;
  final String initialText;

  const _ReviewCommentDialog({
    required this.title,
    required this.label,
    required this.initialText,
  });

  @override
  State<_ReviewCommentDialog> createState() => _ReviewCommentDialogState();
}

class _ReviewCommentDialogState extends State<_ReviewCommentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text;
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context, text);
          },
          child: const Text('ยืนยัน'),
        ),
      ],
    );
  }
}
