import 'dart:io';

import 'package:e_auction/models/technician_profile.dart';
import 'package:e_auction/services/technician_profile_store.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class TechnicianRegisterPage extends StatefulWidget {
  final TechnicianProfile? existing;

  const TechnicianRegisterPage({super.key, this.existing});

  @override
  State<TechnicianRegisterPage> createState() => _TechnicianRegisterPageState();
}

class _PortfolioSlot {
  final String? savedPath;
  final File? newFile;

  const _PortfolioSlot.saved(this.savedPath) : newFile = null;

  const _PortfolioSlot.fresh(this.newFile) : savedPath = null;

  File get file => newFile ?? File(savedPath!);
}

class _JobField {
  final TextEditingController title = TextEditingController();
  final TextEditingController detail = TextEditingController();

  void dispose() {
    title.dispose();
    detail.dispose();
  }
}

class _TechnicianRegisterPageState extends State<TechnicianRegisterPage> {
  static const _maxPhotos = 6;
  static const _maxCertificates = 4;

  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _priceController = TextEditingController();
  final Set<String> _skills = {};
  final List<_PortfolioSlot> _photos = [];
  final List<_PortfolioSlot> _certificates = [];
  final List<_JobField> _jobs = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.displayName;
      _areaController.text = existing.serviceArea;
      _priceController.text = existing.startingPrice.toStringAsFixed(0);
      _skills.addAll(existing.skills);
      _photos.addAll(
        existing.portfolioPaths.map(_PortfolioSlot.saved),
      );
      _certificates.addAll(
        existing.certificatePaths.map(_PortfolioSlot.saved),
      );
      for (final job in existing.jobs) {
        final field = _JobField();
        field.title.text = job.title;
        field.detail.text = job.detail;
        _jobs.add(field);
      }
    }
    if (_jobs.isEmpty) _jobs.add(_JobField());
    if (existing == null) _prefillName();
  }

  Future<void> _prefillName() async {
    final name = await UserDataManager.getName();
    if (!mounted || name == null || name.trim().isEmpty) return;
    if (_nameController.text.isEmpty) {
      setState(() => _nameController.text = name.trim());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    for (final job in _jobs) {
      job.dispose();
    }
    super.dispose();
  }

  Future<void> _addImage(
    List<_PortfolioSlot> target,
    int maxCount,
    ImageSource source,
  ) async {
    if (target.length >= maxCount) {
      _showMessage('เพิ่มรูปได้ไม่เกิน $maxCount รูป');
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
    );
    if (picked == null || !mounted) return;
    setState(() => target.add(_PortfolioSlot.fresh(File(picked.path))));
  }

  void _addJob() {
    setState(() => _jobs.add(_JobField()));
  }

  void _removeJob(int index) {
    if (_jobs.length == 1) return;
    setState(() {
      _jobs.removeAt(index).dispose();
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final area = _areaController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final jobs = _jobs
        .where((job) => job.title.text.trim().isNotEmpty)
        .map((job) => TechnicianJob(
              title: job.title.text,
              detail: job.detail.text,
            ))
        .toList();

    if (name.isEmpty || _skills.isEmpty || area.isEmpty) {
      _showMessage('กรอกชื่อ ทักษะอย่างน้อย 1 อย่าง และพื้นที่ที่รับงาน');
      return;
    }
    if (price == null || price <= 0) {
      _showMessage('กรอกราคาเริ่มต้นให้มากกว่า 0');
      return;
    }
    if (_photos.isEmpty) {
      _showMessage('เพิ่มรูปผลงานอย่างน้อย 1 รูป');
      return;
    }
    if (jobs.isEmpty) {
      _showMessage('เพิ่มงานที่เคยทำอย่างน้อย 1 รายการ');
      return;
    }

    final ownerId = await UserDataManager.getID();
    if (ownerId == null || ownerId.isEmpty) {
      _showMessage('ไม่พบข้อมูลผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await TechnicianProfileStore.submit(
        ownerId: ownerId,
        ownerName: (await UserDataManager.getName())?.trim() ?? name,
        ownerPhone: (await UserDataManager.getPhoneNumber())?.trim() ?? '',
        displayName: name,
        skills: _skills.toList(),
        serviceArea: area,
        startingPrice: price,
        keptPortfolioPaths: _photos
            .map((slot) => slot.savedPath)
            .whereType<String>()
            .toList(),
        newPortfolioFiles: _photos
            .map((slot) => slot.newFile)
            .whereType<File>()
            .toList(),
        keptCertificatePaths: _certificates
            .map((slot) => slot.savedPath)
            .whereType<String>()
            .toList(),
        newCertificateFiles: _certificates
            .map((slot) => slot.newFile)
            .whereType<File>()
            .toList(),
        jobs: jobs,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showMessage('บันทึกไม่สำเร็จ กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'ลงทะเบียนเป็นช่าง' : 'แก้ไขประวัติช่าง',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _field('ชื่อที่แสดง', _nameController, 'เช่น สมชาย ไฟฟ้าและแอร์'),
          const SizedBox(height: 16),
          const Text('ทักษะ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in TechnicianProfile.skillOptions)
                FilterChip(
                  label: Text(skill),
                  selected: _skills.contains(skill),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _skills.add(skill);
                      } else {
                        _skills.remove(skill);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          _field('พื้นที่ที่รับงาน', _areaController, 'เช่น กทม. และนนทบุรี'),
          const SizedBox(height: 16),
          _field(
            'ราคาเริ่มต้น (บาท)',
            _priceController,
            '450',
            keyboard: TextInputType.number,
            formats: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          const Text('รูปผลงาน', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _imageStrip(_photos, _maxPhotos),
          const SizedBox(height: 16),
          const Text(
            'ใบเซอร์ (ไม่จำเป็น)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'เช่น ใบรับรองฝีมือแรงงาน หรือใบอบรม เจ้าหน้าที่ใช้ตอนตรวจ',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          _imageStrip(_certificates, _maxCertificates),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'งานที่เคยทำ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: _addJob,
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มงาน'),
              ),
            ],
          ),
          for (var index = 0; index < _jobs.length; index++) ...[
            _field('ชื่องาน', _jobs[index].title, 'เช่น ล้างแอร์ 2 เครื่อง'),
            const SizedBox(height: 8),
            _field('รายละเอียด', _jobs[index].detail, 'พื้นที่หรือสิ่งที่ทำให้'),
            if (_jobs.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _removeJob(index),
                  child: const Text('ลบงานนี้'),
                ),
              ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: context.customTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_isSaving ? 'กำลังส่ง...' : 'ส่งให้เจ้าหน้าที่ตรวจ'),
          ),
        ],
      ),
    );
  }

  Widget _imageStrip(List<_PortfolioSlot> slots, int maxCount) {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var index = 0; index < slots.length; index++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      slots[index].file,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => slots.removeAt(index)),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _addPhotoButton(slots, maxCount),
        ],
      ),
    );
  }

  Widget _addPhotoButton(List<_PortfolioSlot> slots, int maxCount) {
    return InkWell(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          builder: (context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('เลือกจากคลัง'),
                    onTap: () {
                      Navigator.pop(context);
                      _addImage(slots, maxCount, ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('ถ่ายรูป'),
                    onTap: () {
                      Navigator.pop(context);
                      _addImage(slots, maxCount, ImageSource.camera);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        width: 88,
        height: 88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formats,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: formats,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
