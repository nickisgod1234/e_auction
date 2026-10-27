import 'package:e_auction/models/technician_contact.dart';
import 'package:e_auction/models/technician_profile.dart';
import 'package:e_auction/services/technician_contact_store.dart';
import 'package:e_auction/services/technician_profile_store.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:e_auction/views/first_page/service_page/skill_icon.dart';
import 'package:e_auction/views/first_page/service_page/technician_image.dart';
import 'package:e_auction/views/first_page/service_page/service_jobs_tab.dart';
import 'package:e_auction/views/first_page/service_page/technician_detail_page.dart';
import 'package:e_auction/views/first_page/service_page/technician_register_page.dart';
import 'package:flutter/material.dart';

/// รายการช่างที่อนุมัติแล้วสำหรับผู้ใช้ทั่วไป
/// ทางลงทะเบียนเป็นช่างอยู่ข้างปุ่มรีเฟรชด้านบน
class ServiceProductsPage extends StatefulWidget {
  const ServiceProductsPage({super.key});

  @override
  State<ServiceProductsPage> createState() => _ServiceProductsPageState();
}

class _ServiceProductsPageState extends State<ServiceProductsPage> {
  List<TechnicianProfile> _approved = [];
  Map<String, List<TechnicianReview>> _reviews = {};
  TechnicianProfile? _mine;
  String? _skill;
  int _section = 0;
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final ownerId = await UserDataManager.getID();
    late final List<TechnicianProfile> profiles;
    try {
      profiles = await TechnicianProfileStore.loadAll();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      return;
    }
    late final List<TechnicianReview> reviews;
    try {
      reviews = await TechnicianContactStore.loadReviews();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      return;
    }
    if (!mounted) return;
    final grouped = <String, List<TechnicianReview>>{};
    for (final review in reviews) {
      grouped.putIfAbsent(review.technicianOwnerId, () => []).add(review);
    }
    setState(() {
      _approved = profiles.where((profile) => profile.status == 1).toList();
      _reviews = grouped;
      _mine = ownerId == null || ownerId.isEmpty
          ? null
          : profiles.cast<TechnicianProfile?>().firstWhere(
                (profile) => profile?.ownerId == ownerId,
                orElse: () => null,
              );
      _isLoading = false;
    });
  }

  _Rating? _ratingOf(String ownerId) {
    final reviews = _reviews[ownerId];
    if (reviews == null || reviews.isEmpty) return null;
    final total = reviews.fold<int>(0, (sum, review) => sum + review.stars);
    return _Rating(total / reviews.length, reviews.length);
  }

  bool _matches(TechnicianProfile profile, String skill) {
    if (!profile.skills.contains(skill)) return false;
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    final text = '${profile.displayName} ${profile.serviceArea} ${profile.skills.join(' ')}'
        .toLowerCase();
    return text.contains(query);
  }

  List<TechnicianProfile> _profilesFor(String skill) {
    return _approved.where((profile) => _matches(profile, skill)).toList();
  }

  bool _sectionVisible(String skill) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    if (skill.toLowerCase().contains(query)) return true;
    final samples = SkillSamples.bySkill[skill] ?? const <SkillSample>[];
    if (samples.any((sample) => sample.title.toLowerCase().contains(query))) {
      return true;
    }
    return _profilesFor(skill).isNotEmpty;
  }

  Future<void> _openRegister() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicianRegisterPage(existing: _mine),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _openMine() async {
    final mine = _mine;
    if (mine == null) {
      await _openRegister();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicianDetailPage(
          profile: mine,
          forOwner: true,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final mine = _mine;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'บริการ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: mine == null ? _openRegister : _openMine,
              child: Text(
                mine == null ? 'ลงทะเบียนเป็นช่าง' : 'ประวัติช่างของฉัน',
                style: TextStyle(
                  color: context.customTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_errorMessage!, textAlign: TextAlign.center),
                  ),
                )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      _sectionChip('หาช่าง', 0),
                      const SizedBox(width: 8),
                      _sectionChip('ประกาศจ้าง', 1),
                    ],
                  ),
                ),
                if (_section == 0) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ปัญหาที่ให้ช่วยดูแล เช่น แอร์ไม่เย็น',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        prefixIcon: Icon(Icons.search, color: context.customTheme.primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(color: context.customTheme.primaryColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(color: context.customTheme.primaryColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(color: context.customTheme.primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _skill == null ? _buildHome() : _buildCategory(_skill!),
                  ),
                ] else
                  Expanded(child: ServiceJobsTab(mine: _mine)),
              ],
            ),
    );
  }

  Widget _sectionChip(String label, int section) {
    final selected = _section == section;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _section = section),
    );
  }

  Widget _buildHome() {
    final skills = TechnicianProfile.skillOptions.where(_sectionVisible).toList();
    if (skills.isEmpty) {
      return const Center(
        child: Text('ไม่พบช่างที่ตรงกับคำค้น', style: TextStyle(color: Color(0xFF8A8A8A))),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final skill in skills) ...[
          _sectionHeader(skill),
          _sampleGrid(skill),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildCategory(String skill) {
    final profiles = _profilesFor(skill);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              _sampleCover(skill),
              Positioned(
                left: 8,
                top: 8,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                    onPressed: () => setState(() => _skill = null),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'ช่าง$skill',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1F2A6B)),
        ),
        const SizedBox(height: 12),
        if (profiles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('ยังไม่มีช่างในหมวดนี้', style: TextStyle(color: Color(0xFF8A8A8A))),
          )
        else
          _profileGrid(profiles, skill),
      ],
    );
  }

  Widget _sectionHeader(String skill) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'ช่าง$skill',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2A6B)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() => _skill = skill),
        ),
      ],
    );
  }

  Widget _sampleGrid(String skill) {
    final samples = SkillSamples.bySkill[skill] ?? const <SkillSample>[];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: samples.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        mainAxisExtent: 168,
      ),
      itemBuilder: (context, index) {
        final sample = samples[index];
        return InkWell(
          onTap: () => setState(() => _skill = skill),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  sample.asset,
                  height: 132,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sample.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sampleCover(String skill) {
    final samples = SkillSamples.bySkill[skill];
    if (samples == null || samples.isEmpty) {
      return _photoSlot(skill, height: 190);
    }
    return Image.asset(
      samples.first.asset,
      height: 190,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _profileGrid(List<TechnicianProfile> profiles, String skill) {
    if (profiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('ยังไม่มีช่าง$skill', style: const TextStyle(color: Color(0xFF8A8A8A))),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: profiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        mainAxisExtent: 228,
      ),
      itemBuilder: (context, index) => _profileCard(profiles[index], skill),
    );
  }

  Widget _profileCard(TechnicianProfile profile, String skill) {
    final photo = profile.portfolioPaths.isEmpty ? null : profile.portfolioPaths.first;
    final rating = _ratingOf(profile.ownerId);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TechnicianDetailPage(profile: profile),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 132,
              child: photo == null
                  ? const ColoredBox(
                      color: Color(0xFFF3F4F6),
                      child: Icon(Icons.person_outline, color: Color(0xFF9CA3AF), size: 36),
                    )
                  : technicianImage(photo, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              children: [
                const TextSpan(text: 'เริ่มต้น '),
                TextSpan(
                  text: Format.formatCurrency(profile.startingPrice),
                  style: TextStyle(
                    color: context.customTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (rating == null)
            const Text('ยังไม่มีรีวิว', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))
          else
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Color(0xFFE8A317)),
                const SizedBox(width: 2),
                Text(rating.average.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                Text(
                  ' (${rating.count})',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _photoSlot(String skill, {required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      color: const Color(0xFFFFF4EC),
      alignment: Alignment.center,
      child: SkillIcon(skill, size: height * 0.46),
    );
  }
}

class _Rating {
  final double average;
  final int count;

  const _Rating(this.average, this.count);
}
