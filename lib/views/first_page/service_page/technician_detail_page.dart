import 'package:e_auction/models/technician_contact.dart';
import 'package:e_auction/models/technician_profile.dart';
import 'package:e_auction/services/technician_contact_store.dart';
import 'package:e_auction/services/technician_profile_store.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:e_auction/views/first_page/service_page/skill_icon.dart';
import 'package:e_auction/views/first_page/service_page/technician_chat_page.dart';
import 'package:e_auction/views/first_page/service_page/technician_image.dart';
import 'package:e_auction/views/first_page/service_page/technician_register_page.dart';
import 'package:flutter/material.dart';

/// โปรไฟล์ช่างสำหรับผู้ใช้ทั่วไป หรือสำหรับเจ้าของประวัติ
class TechnicianDetailPage extends StatefulWidget {
  final TechnicianProfile profile;
  final bool forOwner;

  const TechnicianDetailPage({
    super.key,
    required this.profile,
    this.forOwner = false,
  });

  @override
  State<TechnicianDetailPage> createState() => _TechnicianDetailPageState();
}

class _TechnicianDetailPageState extends State<TechnicianDetailPage> {
  late TechnicianProfile _profile;
  String? _viewerId;
  String _viewerName = '';
  List<TechnicianReview> _reviews = [];
  List<TechnicianThread> _threads = [];

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _loadContact();
  }

  Future<void> _loadContact() async {
    final viewerId = await UserDataManager.getID();
    final viewerName = await UserDataManager.getName();
    var reviews = <TechnicianReview>[];
    try {
      reviews = await TechnicianContactStore.reviewsFor(_profile.ownerId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
    var threads = <TechnicianThread>[];
    if (widget.forOwner) {
      try {
        threads = await TechnicianContactStore.threadsForTechnician(_profile.ownerId);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
          );
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _viewerId = viewerId;
      _viewerName = viewerName?.trim() ?? '';
      _reviews = reviews;
      _threads = threads;
    });
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicianRegisterPage(existing: _profile),
      ),
    );
    if (saved != true || !mounted) return;
    final latest = await TechnicianProfileStore.loadByOwner(_profile.ownerId);
    if (!mounted || latest == null) return;
    setState(() => _profile = latest);
  }

  Future<void> _openChat() async {
    final viewerId = _viewerId;
    if (viewerId == null || viewerId.isEmpty) {
      _showMessage('เข้าสู่ระบบก่อนแชทกับช่าง');
      return;
    }
    if (viewerId == _profile.ownerId) {
      _showMessage('นี่คือโปรไฟล์ของคุณ');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicianChatPage(
          customerId: viewerId,
          customerName: _viewerName.isEmpty ? 'ผู้ใช้' : _viewerName,
          technicianOwnerId: _profile.ownerId,
          technicianName: _profile.displayName,
        ),
      ),
    );
    _loadContact();
  }

  Future<void> _openThread(TechnicianThread thread) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicianChatPage(
          customerId: thread.customerId,
          customerName: thread.customerName,
          technicianOwnerId: thread.technicianOwnerId,
          technicianName: _profile.displayName,
          asTechnician: true,
        ),
      ),
    );
    _loadContact();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final comment = _profile.reviewComment?.trim();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _profile.displayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (widget.forOwner) ...[
            _OwnerStatus(profile: _profile),
            const SizedBox(height: 12),
          ],
          SkillIconRow(skills: _profile.skills, size: 28),
          const SizedBox(height: 4),
          Text(
            _profile.serviceArea,
            style: TextStyle(color: Colors.grey[800]),
          ),
          const SizedBox(height: 4),
          Text(
            'ราคาเริ่มต้น ${Format.formatCurrency(_profile.startingPrice)}',
            style: TextStyle(
              color: context.customTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_reviews.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(_ratingLabel(_reviews)),
          ],
          if (widget.forOwner && comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('ความเห็นเจ้าหน้าที่: $comment'),
          ],
          const SizedBox(height: 16),
          const Text('รูปผลงาน', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _ImageStrip(paths: _profile.portfolioPaths),
          if (widget.forOwner) ...[
            const SizedBox(height: 16),
            const Text('ใบเซอร์', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _profile.certificatePaths.isEmpty
                ? Text(
                    'ยังไม่ได้แนบ',
                    style: TextStyle(color: Colors.grey[700]),
                  )
                : _ImageStrip(paths: _profile.certificatePaths),
          ],
          const SizedBox(height: 16),
          const Text('งานที่เคยทำ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final job in _profile.jobs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  title: Text(job.title),
                  subtitle: job.detail.isEmpty ? null : Text(job.detail),
                ),
              ),
            ),
          if (_reviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('รีวิว', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final review in _reviews)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    title: Text('${review.customerName} · ${review.stars} ดาว'),
                    subtitle: review.comment.isEmpty ? null : Text(review.comment),
                  ),
                ),
              ),
          ],
          if (widget.forOwner && _threads.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('ข้อความจากผู้ใช้', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final thread in _threads)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    title: Text(
                      thread.customerName.isEmpty ? 'ผู้ใช้' : thread.customerName,
                    ),
                    subtitle: Text(thread.lastMessage?.text ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openThread(thread),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          if (widget.forOwner)
            OutlinedButton(
              onPressed: _edit,
              child: const Text('แก้ไขประวัติ'),
            )
          else ...[
            FilledButton.icon(
              onPressed: _openChat,
              style: FilledButton.styleFrom(
                backgroundColor: context.customTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('แชทกับช่าง'),
            ),
          ],
        ],
      ),
    );
  }
}

String _ratingLabel(List<TechnicianReview> reviews) {
  final total = reviews.fold<int>(0, (sum, review) => sum + review.stars);
  final average = total / reviews.length;
  return '${average.toStringAsFixed(1)} ดาว · ${reviews.length} รีวิว';
}

class _OwnerStatus extends StatelessWidget {
  final TechnicianProfile profile;

  const _OwnerStatus({required this.profile});

  @override
  Widget build(BuildContext context) {
    final color = switch (profile.status) {
      1 => Colors.green,
      2 => Colors.red,
      _ => Colors.orange,
    };
    final hint = switch (profile.status) {
      1 => 'ผู้ใช้ทั่วไปเห็นโปรไฟล์นี้ในรายการบริการแล้ว',
      2 => 'แก้ไขประวัติแล้วส่งใหม่ได้',
      _ => 'เจ้าหน้าที่กำลังตรวจ ประวัติยังไม่ขึ้นในรายการ',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.statusLabel,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(hint, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
        ],
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  final List<String> paths;

  const _ImageStrip({required this.paths});

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) {
      return Text('ไม่มีรูป', style: TextStyle(color: Colors.grey[700]));
    }
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: technicianImage(
              paths[index],
              width: 88,
              height: 88,
            ),
          );
        },
      ),
    );
  }
}
