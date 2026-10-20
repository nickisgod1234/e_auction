import 'dart:async';

import 'package:e_auction/models/technician_contact.dart';
import 'package:e_auction/services/technician_contact_store.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:flutter/material.dart';

class TechnicianChatPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String technicianOwnerId;
  final String technicianName;

  /// true เมื่อช่างเปิดแชทจากกล่องข้อความของตัวเอง
  final bool asTechnician;

  const TechnicianChatPage({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.technicianOwnerId,
    required this.technicianName,
    this.asTechnician = false,
  });

  @override
  State<TechnicianChatPage> createState() => _TechnicianChatPageState();
}

class _TechnicianChatPageState extends State<TechnicianChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  TechnicianThread? _thread;
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _poll;

  String get _senderId => widget.asTechnician
      ? widget.technicianOwnerId
      : widget.customerId;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (silent && _isSending) return;
    try {
      final thread = await TechnicianContactStore.threadFor(
        customerId: widget.customerId,
        technicianOwnerId: widget.technicianOwnerId,
      );
      if (!mounted) return;
      final grew = (thread?.messages.length ?? 0) > (_thread?.messages.length ?? 0);
      setState(() {
        _thread = thread;
        _isLoading = false;
      });
      if (!silent || grew) _scrollToEnd();
    } catch (error) {
      if (!mounted || silent) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      final thread = await TechnicianContactStore.send(
        customerId: widget.customerId,
        customerName: widget.customerName,
        technicianOwnerId: widget.technicianOwnerId,
        technicianName: widget.technicianName,
        senderId: _senderId,
        text: text,
      );
      if (!mounted) return;
      _controller.clear();
      setState(() => _thread = thread);
      _scrollToEnd();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _review() async {
    var stars = 5;
    final commentController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('รีวิวงาน'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var star = 1; star <= 5; star++)
                        IconButton(
                          onPressed: () => setDialogState(() => stars = star),
                          icon: Icon(
                            star <= stars ? Icons.star : Icons.star_border,
                            color: const Color(0xFFE8A317),
                          ),
                        ),
                    ],
                  ),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ความเห็น (ไม่จำเป็น)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('ยกเลิก'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
    final comment = commentController.text;
    commentController.dispose();
    if (saved != true || !mounted) return;

    await TechnicianContactStore.saveReview(
      customerId: widget.customerId,
      customerName: widget.customerName,
      technicianOwnerId: widget.technicianOwnerId,
      stars: stars,
      comment: comment,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกรีวิวแล้ว')),
    );
  }

  bool get _customerHasWritten {
    final messages = _thread?.messages ?? const <TechnicianMessage>[];
    return messages.any((message) => message.senderId == widget.customerId);
  }

  @override
  Widget build(BuildContext context) {
    final messages = _thread?.messages ?? const <TechnicianMessage>[];
    final title = widget.asTechnician ? widget.customerName : widget.technicianName;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          title.isEmpty ? 'แชท' : title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!widget.asTechnician && _customerHasWritten)
            TextButton(
              onPressed: _review,
              child: const Text('รีวิว'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.isEmpty ? 1 : messages.length,
                    itemBuilder: (context, index) {
                      if (messages.isEmpty) {
                        return const Text(
                          'ส่งข้อความเพื่อถามรายละเอียดและนัดงาน',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF8A8A8A)),
                        );
                      }
                      final message = messages[index];
                      final mine = message.senderId == _senderId;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: mine
                                ? context.customTheme.primaryColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: mine ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
