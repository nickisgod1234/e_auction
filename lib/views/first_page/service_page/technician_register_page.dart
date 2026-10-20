import 'dart:io';

import 'package:e_auction/models/technician_profile.dart';
import 'package:e_auction/views/first_page/service_page/technician_image.dart';
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
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          widget.existing == null ? 'ลงทะเบียนเป็นช่าง' : 'แก้ไขประวัติช่าง',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _section(
                  title: 'ข้อมูลทั่วไป',
                  note: 'ข้อมูลนี้ใช้แสดงในรายการช่างหลังผ่านการตรวจ',
                  children: [
                    _field('ชื่อที่แสดง', _nameController, required: true),
                    const SizedBox(height: 16),
                    _field(
                      'พื้นที่ที่รับงาน',
                      _areaController,
                      hint: 'เขตหรือจังหวัดที่รับงาน',
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'ราคาเริ่มต้น',
                      _priceController,
                      hint: '0',
                      required: true,
                      suffix: 'บาท',
                      keyboard: TextInputType.number,
                      formats: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
                _section(
                  title: 'ทักษะที่รับงาน',
                  note: 'เลือกได้อย่างน้อย 1 รายการ',
                  children: [
                    for (final skill in TechnicianProfile.skillOptions)
                      CheckboxListTile(
                        value: _skills.contains(skill),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(skill, style: const TextStyle(fontSize: 15)),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _skills.add(skill);
                            } else {
                              _skills.remove(skill);
                            }
                          });
                        },
                      ),
                  ],
                ),
                _section(
                  title: 'รูปผลงาน',
                  note: 'อย่างน้อย 1 รูป ไม่เกิน $_maxPhotos รูป',
                  children: [
                    _imageGrid(_photos, _maxPhotos),
                  ],
                ),
                _section(
                  title: 'ใบรับรอง',
                  note: 'ไม่จำเป็น ใช้ประกอบการตรวจ เช่น ใบรับรองฝีมือหรือใบอบรม ไม่เกิน $_maxCertificates ไฟล์',
                  children: [
                    _imageGrid(_certificates, _maxCertificates),
                  ],
                ),
                _section(
                  title: 'ประวัติงาน',
                  note: 'ระบุอย่างน้อย 1 รายการ',
                  children: [
                    for (var index = 0; index < _jobs.length; index++) ...[
                      if (index > 0) const SizedBox(height: 12),
                      _jobCard(index),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _addJob,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('เพิ่มรายการงาน'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.customTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('ส่งให้เจ้าหน้าที่ตรวจ'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required String note,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFB0B7C3)),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _jobCard(int index) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'รายการที่ ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (_jobs.length > 1)
                IconButton(
                  tooltip: 'ลบรายการ',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeJob(index),
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
            ],
          ),
          _field('ชื่องาน', _jobs[index].title, hint: 'ระบุชื่องาน', required: true),
          const SizedBox(height: 12),
          _field('รายละเอียด', _jobs[index].detail, hint: 'ระบุรายละเอียดงาน'),
        ],
      ),
    );
  }

  Widget _imageGrid(List<_PortfolioSlot> slots, int maxCount) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < slots.length; index++)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: slots[index].newFile != null
                    ? Image.file(
                        slots[index].newFile!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      )
                    : technicianImage(
                        slots[index].savedPath ?? '',
                        width: 96,
                        height: 96,
                      ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
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
        if (slots.length < maxCount) _attachTile(slots, maxCount),
      ],
    );
  }

  Widget _attachTile(List<_PortfolioSlot> slots, int maxCount) {
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
                    title: const Text('เลือกจากคลังภาพ'),
                    onTap: () {
                      Navigator.pop(context);
                      _addImage(slots, maxCount, ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('ถ่ายภาพ'),
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
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_outlined, color: Color(0xFF4B5563)),
            SizedBox(height: 4),
            Text(
              'แนบรูป',
              style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool required = false,
    String? suffix,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formats,
  }) {
    final borderColor = const Color(0xFFD1D5DB);
    final radius = BorderRadius.circular(8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: formats,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB0B7C3)),
            suffixText: suffix,
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: context.customTheme.primaryColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
