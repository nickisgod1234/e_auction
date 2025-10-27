import 'package:flutter/material.dart';
import 'package:e_auction/services/product_approval_service.dart';

class ProductDetailModal extends StatelessWidget {
  final ProductQuotation product;

  const ProductDetailModal({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'รายละเอียดสินค้า',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ],
          ),
          Divider(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ข้อมูลทั่วไป
                  _buildSection(
                    'ข้อมูลทั่วไป',
                    [
                      _buildInfoRow('รหัส', product.sequence ?? '-'),
                      _buildInfoRow('ชื่อสินค้า', product.description ?? '-'),
                      _buildInfoRow('รายละเอียด', product.additionalNotes ?? '-'),
                      _buildInfoRow('หมายเหตุ', _getNotes()),
                      _buildInfoRow('ประเภท', product.typeDescription ?? 'ไม่ระบุ'),
                      _buildInfoRow('เบอร์โทร', product.formattedPhone),
                      _buildInfoRow('สถานะ', product.statusText),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // ข้อมูลการประมูล
                  _buildSection(
                    'ข้อมูลการประมูล',
                    [
                      _buildInfoRow('ราคาเริ่มต้น', product.formattedPrice),
                      _buildInfoRow('ขั้นต่ำเพิ่ม', product.formattedMinIncrement),
                      _buildInfoRow('วันที่เริ่ม', _formatDate(product.auctionStartDate)),
                      _buildInfoRow('วันที่สิ้นสุด', _formatDate(product.auctionEndDate)),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // รูปภาพ
                  _buildImageSection(context),
                ],
              ),
            ),
          ),
          
          // Action Buttons
          if (product.canApprove) ...[
            Divider(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showApprovalDialog(context, 'rejected'),
                    icon: Icon(Icons.close, color: Colors.red),
                    label: Text('ปฏิเสธ', style: TextStyle(color: Colors.red)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApprovalDialog(context, 'approved'),
                    icon: Icon(Icons.check),
                    label: Text('อนุมัติ'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildImageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รูปภาพ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: product.imageUrls.isEmpty
              ? Text(
                  'ไม่มีรูปภาพ',
                  style: TextStyle(color: Colors.grey[600]),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.imageUrls.map((imageUrl) {
                    return GestureDetector(
                      onTap: () => _showImageDialog(context, imageUrl),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('ProductDetailModal Image load error: $error');
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  String _getNotes() {
    if (product.messages != null && product.messages!.isNotEmpty) {
      return product.messages!.first.quotationMessage ?? '-';
    }
    return '-';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // รูปภาพขนาดใหญ่
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 300,
                      height: 300,
                      color: Colors.grey[800],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'ไม่สามารถโหลดรูปภาพได้',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 300,
                      height: 300,
                      color: Colors.grey[800],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'กำลังโหลดรูปภาพ...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // ปุ่มปิด
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            // URL ของรูปภาพ (ด้านล่าง)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  imageUrl,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApprovalDialog(BuildContext context, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'approved' ? 'อนุมัติสินค้า' : 'ปฏิเสธสินค้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชื่อสินค้า: ${product.description ?? '-'}'),
            SizedBox(height: 8),
            Text('เบอร์โทร: ${product.formattedPhone}'),
            SizedBox(height: 8),
            Text('ราคาเริ่มต้น: ${product.formattedPrice}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // ปิด modal ด้วย
              // TODO: Call approval API
            },
            child: Text(status == 'approved' ? 'อนุมัติ' : 'ปฏิเสธ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
