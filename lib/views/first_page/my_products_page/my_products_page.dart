import 'package:e_auction/services/my_products_service.dart';
import 'package:e_auction/services/product_approval_service.dart';
import 'package:e_auction/services/product_status_notifier.dart';
import 'package:e_auction/views/first_page/chat_page/chat_page.dart';
import 'package:flutter/material.dart';

/// หน้าแสดงสินค้าที่ผู้ใช้ลงประมูลไว้เอง พร้อมสถานะการอนุมัติจากเจ้าหน้าที่
class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<ProductQuotation> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await MyProductsService.getMyProducts();

      // เก็บสถานะล่าสุดไว้ให้ตัวเฝ้าดูใช้เทียบ จะได้แจ้งเตือนเมื่อผลอนุมัติเปลี่ยน
      await ProductStatusNotifier.recordSnapshot(products);

      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// status: null/0 รออนุมัติ, 1 อนุมัติแล้ว, 2 ปฏิเสธ
  List<ProductQuotation> _byStatus(int? status) {
    if (status == null) return _products;
    if (status == 0) {
      return _products
          .where((p) => p.status == null || p.status == 0)
          .toList();
    }
    return _products.where((p) => p.status == status).toList();
  }

  Color _statusColor(ProductQuotation product) {
    switch (product.statusColor) {
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(ProductQuotation product) {
    switch (product.status) {
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  String _statusHint(ProductQuotation product) {
    // ถ้า ERP ส่งเหตุผลจริงมาแล้ว ไม่ต้องไล่ผู้ใช้ไปถามในแชทอีก
    // แต่ข้อความสำเร็จรูปไม่นับ เพราะอ่านแล้วก็ยังไม่รู้เหตุผล
    final hasComment = product.meaningfulApprovalComment != null;

    switch (product.status) {
      case 1:
        return 'พร้อมเข้าร่วมประมูลตามวันและเวลาที่กำหนด';
      case 2:
        return hasComment
            ? 'สินค้าไม่ผ่านการอนุมัติ ดูเหตุผลจากเจ้าหน้าที่ด้านล่าง'
            : 'สินค้าไม่ผ่านการอนุมัติ สอบถามเหตุผลได้ที่แชทกับเจ้าหน้าที่';
      default:
        return 'เจ้าหน้าที่กำลังตรวจสอบ จะแจ้งผลทางแชทเมื่อพิจารณาเสร็จ';
    }
  }

  /// ERP ส่งบางฟิลด์มาเป็นวันที่เปล่าๆ (2025-10-16) จึงไม่แสดงเวลาให้เข้าใจผิด
  String _formatDate(String? raw) {
    final value = raw?.trim() ?? '';
    final date = DateTime.tryParse(value);
    if (date == null) return '-';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final formatted = '$day/$month/${local.year}';

    final hasTime = value.contains(' ') || value.contains('T');
    if (!hasTime) return formatted;

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$formatted $hour:$minute';
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'สินค้าของฉัน',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black, size: 20),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(null),
                _buildList(0),
                _buildList(1),
                _buildList(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          color: Colors.grey[500],
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          _buildTab('ทั้งหมด', _byStatus(null).length),
          _buildTab('รออนุมัติ', _byStatus(0).length),
          _buildTab('อนุมัติแล้ว', _byStatus(1).length),
          _buildTab('ปฏิเสธ', _byStatus(2).length),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          '$label\n$count',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildList(int? status) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildMessageState(
        icon: Icons.wifi_off,
        title: 'โหลดข้อมูลไม่สำเร็จ',
        subtitle: _errorMessage!,
        action: TextButton.icon(
          onPressed: _loadProducts,
          icon: const Icon(Icons.refresh),
          label: const Text('ลองใหม่'),
        ),
      );
    }

    final products = _byStatus(status);
    if (products.isEmpty) {
      return _buildMessageState(
        icon: Icons.inventory_2_outlined,
        title: status == null
            ? 'คุณยังไม่ได้ลงสินค้าประมูล'
            : 'ไม่มีสินค้าในสถานะนี้',
        subtitle: status == null
            ? 'ลงสินค้าประมูลได้จากเมนู "เพิ่มสินค้าประมูล"'
            : 'ลองดูแท็บอื่นเพื่อตรวจสอบสถานะสินค้าของคุณ',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
        itemCount: products.length,
        itemBuilder: (context, index) => _buildProductCard(products[index]),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductQuotation product) {
    final statusColor = _statusColor(product);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(product),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.description?.trim().isNotEmpty ?? false
                            ? product.description!.trim()
                            : 'ไม่ระบุชื่อสินค้า',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildStatusChip(product, statusColor),
                      const SizedBox(height: 6),
                      Text(
                        'ราคาเริ่มต้น ${product.formattedPrice}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildInfoRow('รหัสรายการ', '#${product.quotationId}'),
            _buildInfoRow('วันที่ลงสินค้า', _formatDate(product.createdAt)),
            _buildInfoRow(
              'ช่วงประมูล',
              '${_formatDate(product.auctionStartDate)} - '
                  '${_formatDate(product.auctionEndDate)}',
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusHint(product),
                style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              ),
            ),
            if (product.meaningfulApprovalComment != null) ...[
              const SizedBox(height: 8),
              _buildApprovalComment(
                product.meaningfulApprovalComment!,
                statusColor,
              ),
            ],
            if (product.status == 1 || product.status == 2) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('ดูข้อความจากเจ้าหน้าที่'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// เหตุผลที่เจ้าหน้าที่กรอกตอนพิจารณา แสดงเฉพาะใบที่มีค่าจริง
  ///
  /// เก็บไว้ที่ ERP จึงไม่หายไปแม้ผู้ใช้ลบแชทหรือลงแอปใหม่
  Widget _buildApprovalComment(String comment, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                'ความเห็นจากเจ้าหน้าที่',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: TextStyle(fontSize: 12, color: Colors.grey[900]),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(ProductQuotation product) {
    final imageUrls = product.imageUrls;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        color: Colors.grey[200],
        child: imageUrls.isEmpty
            ? Icon(Icons.image_not_supported,
                color: Colors.grey[400], size: 28)
            : Image.network(
                imageUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image,
                  color: Colors.grey[400],
                  size: 28,
                ),
              ),
      ),
    );
  }

  Widget _buildStatusChip(ProductQuotation product, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(product), size: 14, color: statusColor),
          const SizedBox(width: 4),
          Text(
            product.statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
