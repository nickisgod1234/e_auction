import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_auction/services/product_approval_service.dart';
import 'package:e_auction/views/first_page/admin_dashboard/product_detail_modal.dart';

class ProductApprovalPage extends StatefulWidget {
  const ProductApprovalPage({super.key});

  @override
  State<ProductApprovalPage> createState() => _ProductApprovalPageState();
}


// Separate StatefulWidget for Image Gallery Dialog to avoid freeze issues
class _ImageGalleryDialog extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageGalleryDialog({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ImageGalleryDialog> createState() => _ImageGalleryDialogState();
}

class _ImageGalleryDialogState extends State<_ImageGalleryDialog> {
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // รูปภาพขนาดใหญ่
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      width: 300,
                      height: 300,
                      color: Colors.grey[800],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text('กำลังโหลดรูปภาพ...', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 300,
                      height: 300,
                      color: Colors.grey[800],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, color: Colors.grey[400], size: 64),
                          SizedBox(height: 16),
                          Text('ไม่สามารถโหลดรูปภาพได้', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                        ],
                      ),
                    ),
                    fadeInDuration: const Duration(milliseconds: 200),
                  ),
                ),
              );
            },
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
          // Thumbnail Gallery (ถ้ามีหลายรูป)
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                height: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot indicators
                    Container(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.imageUrls.length,
                          (index) => Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Thumbnail Gallery
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.imageUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 8),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedIndex == index
                                      ? Colors.orange
                                      : Colors.white.withOpacity(0.3),
                                  width: _selectedIndex == index ? 3 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: widget.imageUrls[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[800],
                                    child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 20),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[800],
                                    child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 20),
                                  ),
                                  fadeInDuration: const Duration(milliseconds: 200),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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

class _ProductApprovalPageState extends State<ProductApprovalPage> {
  List<ProductQuotation> _products = [];
  bool _isLoading = false;
  String _selectedStatus = '';
  String _selectedType = '';
  String? _selectedDate;
  late ProductApprovalService _productApprovalService;

  @override
  void initState() {
    super.initState();
    _productApprovalService = ProductApprovalService.defaultInstance();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _productApprovalService.getPendingProducts(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        type: _selectedType.isEmpty ? null : _selectedType,
        date: _selectedDate,
      );
      
      if (response.status == 'success') {
        setState(() {
          _products = response.data;
        });
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveProduct(ProductQuotation product, String status) async {
    try {
      final response = await _productApprovalService.approveProduct(
        quotationId: product.quotationId,
        status: status,
        comment: status == 'approved' ? 'อนุมัติโดย admin' : 'ปฏิเสธโดย admin',
      );
      
      if (response.status == 'success') {
        _showSuccessSnackBar(
          status == 'approved' ? 'อนุมัติสินค้าสำเร็จ' : 'ปฏิเสธสินค้าสำเร็จ'
        );
        _loadProducts();
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการอนุมัติ: $e');
    }
  }

  void _showApprovalDialog(ProductQuotation product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('อนุมัติสินค้า'),
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _approveProduct(product, 'rejected');
            },
            child: Text('ปฏิเสธ', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveProduct(product, 'approved');
            },
            child: Text('อนุมัติ'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(ProductQuotation product) async {
    try {
      final response = await _productApprovalService.getProductDetail(product.quotationId);
      if (response.status == 'success' && response.data.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => ProductDetailModal(product: response.data.first),
        );
      } else {
        _showErrorSnackBar('ไม่สามารถโหลดรายละเอียดสินค้าได้');
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดรายละเอียด: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildProductImage(ProductQuotation product, int productIndex) {
    final imageUrls = product.imageUrls;
    
    if (imageUrls.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: 30,
        ),
      );
    }
    
    final imageUrl = imageUrls.first;
    
    return GestureDetector(
      onTap: () => _showImageDialog(imageUrls, 0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[200],
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[200],
              child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
            ),
            fadeInDuration: const Duration(milliseconds: 200),
          ),
          if (imageUrls.length > 1)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${imageUrls.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showImageDialog(List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ImageGalleryDialog(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('อนุมัติสินค้า'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus.isEmpty ? null : _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'สถานะ',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(value: '', child: Text('ทั้งหมด')),
                          DropdownMenuItem(value: 'pending', child: Text('รออนุมัติ')),
                          DropdownMenuItem(value: 'approved', child: Text('อนุมัติแล้ว')),
                          DropdownMenuItem(value: 'rejected', child: Text('ปฏิเสธ')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value ?? '';
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType.isEmpty ? null : _selectedType,
                        decoration: InputDecoration(
                          labelText: 'ประเภท',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(value: '', child: Text('ทั้งหมด')),
                          DropdownMenuItem(value: '3', child: Text('ใบประมูลราคาปกติ')),
                          DropdownMenuItem(value: '4', child: Text('ใบประมูลราคาต่ำสุด')),
                          DropdownMenuItem(value: '5', child: Text('ใบประมูลราคาสูงสุด')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value ?? '';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'วันที่สร้าง',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        controller: TextEditingController(
                          text: _selectedDate,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _loadProducts,
                      child: Text('ค้นหา'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = '';
                          _selectedType = '';
                          _selectedDate = null;
                        });
                        _loadProducts();
                      },
                      child: Text('รีเซ็ต'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Products List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'ไม่พบข้อมูล',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // รูปภาพสินค้า
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: _buildProductImage(product, index),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      // ข้อมูลสินค้า
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    product.description ?? 'ไม่ระบุชื่อสินค้า',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: product.statusColor == 'orange' 
                                                        ? Colors.orange[100] 
                                                        : product.statusColor == 'green'
                                                            ? Colors.green[100]
                                                            : Colors.red[100],
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    product.statusText,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: product.statusColor == 'orange' 
                                                          ? Colors.orange[800] 
                                                          : product.statusColor == 'green'
                                                              ? Colors.green[800]
                                                              : Colors.red[800],
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.phone, size: 14, color: Colors.grey),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    product.formattedPhone,
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.attach_money, size: 14, color: Colors.grey),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    product.formattedPrice,
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, size: 14, color: Colors.grey),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    product.createdAt != null 
                                                        ? '${DateTime.parse(product.createdAt!).day}/${DateTime.parse(product.createdAt!).month} ${DateTime.parse(product.createdAt!).hour.toString().padLeft(2, '0')}:${DateTime.parse(product.createdAt!).minute.toString().padLeft(2, '0')}'
                                                        : '-',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showProductDetail(product),
                                          icon: Icon(Icons.visibility, size: 16),
                                          label: Text('ดูรายละเอียด'),
                                        ),
                                      ),
                                      if (product.canApprove) ...[
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showApprovalDialog(product),
                                            icon: Icon(Icons.approval, size: 16),
                                            label: Text('อนุมัติ'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
