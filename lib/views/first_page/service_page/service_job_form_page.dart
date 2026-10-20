import 'package:e_auction/models/technician_profile.dart';
import 'package:e_auction/services/service_job_store.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServiceJobFormPage extends StatefulWidget {
  const ServiceJobFormPage({super.key});

  @override
  State<ServiceJobFormPage> createState() => _ServiceJobFormPageState();
}

class _ServiceJobFormPageState extends State<ServiceJobFormPage> {
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  final _areaController = TextEditingController();
  final _budgetController = TextEditingController();
  String? _skill;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _areaController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final area = _areaController.text.trim();
    final skill = _skill;
    final budgetText = _budgetController.text.trim();
    final budget = budgetText.isEmpty ? null : double.tryParse(budgetText);

    if (skill == null || title.isEmpty || area.isEmpty) {
      _showMessage('เลือกประเภทงาน กรอกชื่องาน และพื้นที่');
      return;
    }
    if (budgetText.isNotEmpty && (budget == null || budget <= 0)) {
      _showMessage('งบประมาณต้องมากกว่า 0 หรือเว้นว่าง');
      return;
    }

    final ownerId = await UserDataManager.getID();
    if (ownerId == null || ownerId.isEmpty) {
      _showMessage('เข้าสู่ระบบก่อนประกาศจ้าง');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final name = (await UserDataManager.getName())?.trim();
      await ServiceJobStore.create(
        ownerId: ownerId,
        ownerName: name == null || name.isEmpty ? 'ผู้ใช้' : name,
        skill: skill,
        title: title,
        detail: _detailController.text,
        area: area,
        budget: budget,
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ประกาศจ้างช่าง',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text('ประเภทงาน', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in TechnicianProfile.skillOptions)
                ChoiceChip(
                  label: Text(skill),
                  selected: _skill == skill,
                  onSelected: (_) => setState(() => _skill = skill),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _field('ชื่องาน', _titleController, 'เช่น ล้างแอร์ 2 เครื่อง'),
          const SizedBox(height: 12),
          _field('รายละเอียด', _detailController, 'อาการหรือสิ่งที่ต้องการ'),
          const SizedBox(height: 12),
          _field('พื้นที่', _areaController, 'เช่น นนทบุรี'),
          const SizedBox(height: 12),
          _field(
            'งบประมาณ (ไม่จำเป็น)',
            _budgetController,
            '1200',
            keyboard: TextInputType.number,
            formats: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: context.customTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_isSaving ? 'กำลังประกาศ...' : 'ประกาศให้ช่างเสนอราคา'),
          ),
        ],
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
