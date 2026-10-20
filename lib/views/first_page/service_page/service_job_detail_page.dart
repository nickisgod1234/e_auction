import 'package:e_auction/models/service_job.dart';
import 'package:e_auction/models/technician_profile.dart';
import 'package:e_auction/services/service_job_store.dart';
import 'package:e_auction/services/technician_profile_store.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/utils/user_data_manager.dart';
import 'package:e_auction/views/first_page/service_page/technician_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServiceJobDetailPage extends StatefulWidget {
  final ServiceJob job;
  final TechnicianProfile? mine;

  const ServiceJobDetailPage({
    super.key,
    required this.job,
    this.mine,
  });

  @override
  State<ServiceJobDetailPage> createState() => _ServiceJobDetailPageState();
}

class _ServiceJobDetailPageState extends State<ServiceJobDetailPage> {
  late ServiceJob _job;
  List<ServiceQuote> _quotes = [];
  String? _viewerId;
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  bool get _isOwner => _viewerId != null && _viewerId == _job.ownerId;

  bool get _canQuote {
    final mine = widget.mine;
    return mine != null &&
        mine.status == 1 &&
        mine.ownerId != _job.ownerId &&
        mine.skills.contains(_job.skill) &&
        _job.isOpen;
  }

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _load();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final viewerId = await UserDataManager.getID();
    final quotes = await ServiceJobStore.quotesFor(_job.id);
    if (!mounted) return;
    ServiceQuote? mineQuote;
    for (final quote in quotes) {
      if (quote.technicianOwnerId == widget.mine?.ownerId) {
        mineQuote = quote;
        break;
      }
    }
    if (mineQuote != null && _priceController.text.isEmpty) {
      _priceController.text = mineQuote.price.toStringAsFixed(0);
      _noteController.text = mineQuote.note;
    }
    final visible = viewerId == _job.ownerId
        ? quotes
        : (mineQuote == null ? <ServiceQuote>[] : [mineQuote]);
    setState(() {
      _viewerId = viewerId;
      _quotes = visible;
    });
  }

  Future<void> _submitQuote() async {
    final mine = widget.mine;
    final price = double.tryParse(_priceController.text.trim());
    if (mine == null || price == null) {
      _showMessage('กรอกราคาที่เสนอ');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ServiceJobStore.submitQuote(
        jobId: _job.id,
        technicianOwnerId: mine.ownerId,
        technicianName: mine.displayName,
        price: price,
        note: _noteController.text,
      );
      if (!mounted) return;
      _showMessage('ส่งราคาแล้ว');
      await _load();
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _award(ServiceQuote quote) async {
    final ownerId = _viewerId;
    if (ownerId == null) return;
    setState(() => _isSaving = true);
    try {
      final updated = await ServiceJobStore.award(
        jobId: _job.id,
        ownerId: ownerId,
        quoteId: quote.id,
      );
      if (!mounted) return;
      setState(() => _job = updated);
      _showMessage('เลือก ${quote.technicianName} แล้ว');
      await _load();
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openTechnician(String ownerId) async {
    final profile = await TechnicianProfileStore.loadByOwner(ownerId);
    if (!mounted || profile == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TechnicianDetailPage(profile: profile),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final budget = _job.budget;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _job.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(_job.statusLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('${_job.skill} · ${_job.area}'),
          if (_job.detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_job.detail),
          ],
          const SizedBox(height: 8),
          Text(
            budget == null
                ? 'ไม่ได้ระบุงบ'
                : 'งบประมาณ ${Format.formatCurrency(budget)}',
          ),
          if (_isOwner || _canQuote || _quotes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            _isOwner ? 'ราคาที่ช่างเสนอ' : 'ราคาของฉัน',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_quotes.isEmpty)
            Text(
              _isOwner ? 'ยังไม่มีช่างเสนอราคา' : 'ยังไม่ได้เสนอราคา',
              style: TextStyle(color: Colors.grey[700]),
            ),
          for (final quote in _quotes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  title: Text(quote.technicianName),
                  subtitle: Text(
                    '${Format.formatCurrency(quote.price)}'
                    '${quote.note.isEmpty ? '' : '\n${quote.note}'}'
                    '${_job.awardedQuoteId == quote.id ? '\nเลือกแล้ว' : ''}',
                  ),
                  isThreeLine: quote.note.isNotEmpty,
                  onTap: () => _openTechnician(quote.technicianOwnerId),
                  trailing: _isOwner && _job.isOpen
                      ? TextButton(
                          onPressed: _isSaving ? null : () => _award(quote),
                          child: const Text('เลือก'),
                        )
                      : null,
                ),
              ),
            ),
          ],
          if (_canQuote) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'ราคาที่เสนอ (บาท)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'รายละเอียดข้อเสนอ (ไม่จำเป็น)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSaving ? null : _submitQuote,
              style: FilledButton.styleFrom(
                backgroundColor: context.customTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(_isSaving ? 'กำลังส่ง...' : 'ส่งราคา'),
            ),
          ],
        ],
      ),
    );
  }
}
