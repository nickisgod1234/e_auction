import 'dart:io';

import 'package:e_auction/models/technician_profile.dart';
import 'package:e_auction/services/technician_profile_store.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:e_auction/views/first_page/service_page/technician_detail_page.dart';
import 'package:e_auction/views/first_page/service_page/technician_register_page.dart';
import 'package:flutter/material.dart';

/// รายการช่างที่อนุมัติแล้วสำหรับผู้ใช้ทั่วไป
/// ทางลงทะเบียนเป็นช่างอยู่ปุ่มล่างแยกจากรายการ
class ServiceProductsPage extends StatefulWidget {
  const ServiceProductsPage({super.key});

  @override
  State<ServiceProductsPage> createState() => _ServiceProductsPageState();
}

class _ServiceProductsPageState extends State<ServiceProductsPage> {
  List<TechnicianProfile> _approved = [];
  TechnicianProfile? _mine;
  String? _skill;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final ownerId = await UserDataManager.getID();
    final profiles = await TechnicianProfileStore.loadAll();
    if (!mounted) return;
    setState(() {
      _approved = profiles.where((profile) => profile.status == 1).toList();
      _mine = ownerId == null || ownerId.isEmpty
          ? null
          : profiles.cast<TechnicianProfile?>().firstWhere(
                (profile) => profile?.ownerId == ownerId,
                orElse: () => null,
              );
      _isLoading = false;
    });
  }

  List<TechnicianProfile> get _visible {
    final skill = _skill;
    if (skill == null) return _approved;
    return _approved.where((profile) => profile.skills.contains(skill)).toList();
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
          'สินค้าบริการ',
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 20),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('ทั้งหมด'),
                          selected: _skill == null,
                          onSelected: (_) => setState(() => _skill = null),
                        ),
                      ),
                      for (final skill in TechnicianProfile.skillOptions)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(skill),
                            selected: _skill == skill,
                            onSelected: (_) => setState(() => _skill = skill),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(child: _buildList()),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: mine == null
              ? FilledButton(
                  onPressed: _openRegister,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.customTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('ลงทะเบียนเป็นช่าง'),
                )
              : OutlinedButton(
                  onPressed: _openMine,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text('ประวัติช่างของฉัน · ${mine.statusLabel}'),
                ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final profiles = _visible;
    if (profiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _skill == null
                ? 'ยังไม่มีช่างที่ผ่านการตรวจ'
                : 'ยังไม่มีช่างประเภท$_skill',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8A8A8A)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: profiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final photo = profile.portfolioPaths.isEmpty
            ? null
            : profile.portfolioPaths.first;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: photo == null
                  ? Container(
                      width: 56,
                      height: 56,
                      color: const Color(0xFFFFF1EC),
                      child: Icon(
                        Icons.handyman_outlined,
                        color: context.customTheme.primaryColor,
                      ),
                    )
                  : Image.file(
                      File(photo),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            title: Text(profile.displayName),
            subtitle: Text(
              '${profile.skills.join(' · ')}\n${profile.serviceArea} · เริ่ม ${Format.formatCurrency(profile.startingPrice)}',
            ),
            isThreeLine: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TechnicianDetailPage(profile: profile),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
