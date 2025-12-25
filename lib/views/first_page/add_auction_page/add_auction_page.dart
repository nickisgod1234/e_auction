import 'package:flutter/material.dart';
import 'widget_add/add_auction_widgets.dart';
import 'widget_add/add_auction_methods.dart';
import 'widget_add/add_auction_state.dart';
import 'promotion_policy_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:e_auction/utils/format.dart';

class AddAuctionPage extends StatefulWidget {
  const AddAuctionPage({super.key});

  @override
  State<AddAuctionPage> createState() => _AddAuctionPageState();
}

// Dialog for selecting previous auction to relist
class _RelistAuctionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> previousAuctions;
  final Function(Map<String, dynamic>) onSelect;

  const _RelistAuctionDialog({
    required this.previousAuctions,
    required this.onSelect,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.repeat, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'เลือกสินค้าเก่ามาลงซ้ำ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: previousAuctions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'ไม่มีสินค้าเก่า',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: previousAuctions.length,
                      padding: EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final auction = previousAuctions[index];
                        
                        // Build image URL from image data
                        String? displayImageUrl;
                        final imageData = auction['image_url']?.toString() ?? '';
                        if (imageData.isNotEmpty) {
                          final imageUrls = AddAuctionMethods.parseImageUrls(imageData);
                          if (imageUrls.isNotEmpty) {
                            displayImageUrl = AddAuctionMethods.buildImageUrl(imageUrls.first);
                          } else {
                            displayImageUrl = AddAuctionMethods.buildImageUrl(imageData);
                          }
                        }
                        
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => onSelect(auction),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Image or placeholder
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: displayImageUrl != null && displayImageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              displayImageUrl,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            loadingProgress.expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(Icons.image, color: Colors.grey[400]);
                                              },
                                            ),
                                          )
                                        : Icon(Icons.image, color: Colors.grey[400]),
                                  ),
                                  SizedBox(width: 12),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          auction['product_name'] ?? 'ไม่มีชื่อสินค้า',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                                            SizedBox(width: 4),
                                            Text(
                                              Format.formatCurrency(
                                                double.tryParse(auction['starting_price'] ?? '0') ?? 0,
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                            SizedBox(width: 4),
                                            Text(
                                              'สิ้นสุด: ${_formatDate(auction['end_date'])}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('ยกเลิก'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAuctionPageState extends State<AddAuctionPage> {
  late AddAuctionState _state;

  @override
  void initState() {
    super.initState();
    _state = AddAuctionState();
    _state.initializeDefaults();
    _loadQuotationTypes();
  }

  Future<void> _showRelistDialog() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Load previous auctions
      final previousAuctions = await AddAuctionMethods.getUserPreviousAuctions();
      
      // Close loading
      Navigator.of(context).pop();

      if (previousAuctions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('คุณยังไม่มีสินค้าที่เคยลงไปแล้ว'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show selection dialog
      showDialog(
        context: context,
        builder: (context) => _RelistAuctionDialog(
          previousAuctions: previousAuctions,
          onSelect: (auction) {
            _loadPreviousAuctionData(auction);
            Navigator.of(context).pop();
          },
        ),
      );
    } catch (e) {
      // Close loading if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadPreviousAuctionData(Map<String, dynamic> auction) async {
    // Set flag to indicate relisting
    _state.isRelistingFromPrevious = true;
    
    // Load ALL data from previous auction EXCEPT dates
    _state.productNameController.text = auction['product_name'] ?? '';
    _state.descriptionController.text = auction['description'] ?? '';
    _state.notesController.text = auction['notes'] ?? '';
    _state.startingPriceController.text = auction['starting_price'] ?? '0';
    _state.minIncrementController.text = auction['min_increment'] ?? '0';
    
    // DO NOT load dates - user must select new dates
    _state.startDate = null;
    _state.endDate = null;

    // Set quotation type
    if (auction['purchase_order_type_id'] != null) {
      _state.updateSelectedQuotationType(
        auction['purchase_order_type_id'],
        auction['quotation_type_name'],
        auction['quotation_type_code'],
      );
    }

    // Set quantity if available
    if (auction['quantity'] != null) {
      _state.quantityController.text = auction['quantity'];
    }

    // Load images from previous auction
    _state.clearSelectedImages();
    final imageUrl = auction['image_url']?.toString() ?? '';
    
    if (imageUrl.isNotEmpty) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Parse image URLs
        List<String> imageUrls = AddAuctionMethods.parseImageUrls(imageUrl);
        
        if (imageUrls.isEmpty) {
          // Try to build URL from single image name
          final builtUrl = AddAuctionMethods.buildImageUrl(imageUrl);
          if (builtUrl.isNotEmpty) {
            imageUrls = [builtUrl];
          }
        } else {
          // Build full URLs for each image name
          imageUrls = imageUrls.map((img) {
            final builtUrl = AddAuctionMethods.buildImageUrl(img);
            return builtUrl.isNotEmpty ? builtUrl : img;
          }).where((url) => url.isNotEmpty).toList();
        }

        // Download images (limit to 5 images)
        int downloadedCount = 0;
        for (final url in imageUrls) {
          if (downloadedCount >= 5) break;
          
          final file = await AddAuctionMethods.downloadImageFromUrl(url);
          if (file != null) {
            _state.addSelectedImage(file);
            downloadedCount++;
          }
        }

        // Close loading dialog
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        setState(() {});

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text('โหลดข้อมูลสินค้าเก่าแล้ว'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'โหลดข้อมูลสินค้าเก่าทั้งหมดแล้ว (รวมรูปภาพ ${downloadedCount} รูป)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'กรุณาเลือก:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'วันที่เริ่มต้นและสิ้นสุด (จำเป็น)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('เข้าใจแล้ว'),
              ),
            ],
          ),
        );
      } catch (e) {
        // Close loading dialog if still open
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        
        setState(() {});

        // Show dialog with warning about images
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text('โหลดข้อมูลสินค้าเก่าแล้ว'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'โหลดข้อมูลสินค้าเก่าทั้งหมดแล้ว',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'กรุณาเลือก:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'วันที่เริ่มต้นและสิ้นสุด (จำเป็น)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ไม่สามารถโหลดรูปภาพได้ กรุณาเลือกรูปภาพใหม่',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('เข้าใจแล้ว'),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() {});

      // Show dialog without image info
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text('โหลดข้อมูลสินค้าเก่าแล้ว'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'โหลดข้อมูลสินค้าเก่าทั้งหมดแล้ว',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'กรุณาเลือก:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'วันที่เริ่มต้นและสิ้นสุด (จำเป็น)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[700]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'กรุณาเลือกรูปภาพสินค้า',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('เข้าใจแล้ว'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _loadQuotationTypes() async {
    _state.updateLoadingQuotationTypes(true);
    setState(() {});

    try {
      final types = await AddAuctionMethods.loadQuotationTypes();
      _state.updateQuotationTypes(types);
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการโหลดประเภทสินค้า: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _state.updateLoadingQuotationTypes(false);
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    if (_state.selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เพิ่มรูปภาพได้สูงสุด 5 รูป'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final image = await AddAuctionMethods.pickImage();
    if (image != null) {
      _state.addSelectedImage(image);
      setState(() {});
    }
  }

  Future<void> _takePhoto() async {
    if (_state.selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เพิ่มรูปภาพได้สูงสุด 5 รูป'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final image = await AddAuctionMethods.takePhoto();
    if (image != null) {
      _state.addSelectedImage(image);
      setState(() {});
    }
  }
  
  void _removeImage(int index) {
    _state.removeSelectedImage(index);
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final date = await AddAuctionMethods.selectDate(context, isStartDate);
    if (date != null) {
      if (isStartDate) {
        _state.updateStartDate(date);
      } else {
        _state.updateEndDate(date);
      }
      setState(() {});
    }
  }

  void _updatePercentageMode(bool isPercentage) {
    _state.updatePercentageMode(isPercentage);
    setState(() {});
  }

  void _updatePercentageValue(double value) {
    _state.updatePercentageValue(value);
    setState(() {});
  }

  Future<void> _openLineOA() async {
    const lineUrl = 'https://line.me/R/ti/p/@770psqfc';
    final Uri uri = Uri.parse(lineUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try to open Line app directly
        const lineAppUrl = 'line://ti/p/@770psqfc';
        final Uri lineAppUri = Uri.parse(lineAppUrl);
        if (await canLaunchUrl(lineAppUri)) {
          await launchUrl(lineAppUri);
        } else {
          throw Exception('ไม่สามารถเปิด Line ได้');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเปิด Line ได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateQuotationType(String? id, String? name) {
    // Find the selected type to get the code
    String? typeCode;
    if (id != null) {
      final selectedType = _state.quotationTypes.firstWhere(
        (type) => type['id'].toString() == id,
        orElse: () => {'code': ''},
      );
      typeCode = selectedType['code']?.toString();
    }

    _state.updateSelectedQuotationType(id, name, typeCode);
    setState(() {});
  }

  void _showAdminContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ข้อมูลติดต่อ Admin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'หากมีปัญหาในการใช้งานหรือต้องการความช่วยเหลือ กรุณาติดต่อ Admin ได้ที่:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'อีเมลล์:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'sale@cloudmate-th.com',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _openLineOA,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Line OA:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@770psqfc',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new,
                        color: Colors.green[700],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เวลาตอบกลับ:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '24 ชั่วโมง',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'ปิด',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // TODO: Implement email opening functionality
            //     Navigator.of(context).pop();
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(
            //         content: Text('เปิดอีเมลล์: nickisgods@gmail.com'),
            //         backgroundColor: Colors.blue,
            //       ),
            //     );
            //   },
            //   icon: const Icon(Icons.email, size: 16),
            //   label: const Text('ส่งอีเมลล์'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.blue[600],
            //     foregroundColor: Colors.white,
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            // ),
          ],
        );
      },
    );
  }

  void _showImageSelectionDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เลือกรูปภาพสินค้า',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                      icon: Icon(Icons.photo_library),
                      label: Text('เลือกรูปจากแกลเลอรี่'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _takePhoto();
                      },
                      icon: Icon(Icons.camera_alt),
                      label: Text('ถ่ายรูปใหม่'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('ยกเลิก'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    // ตรวจสอบว่ามีรูปภาพหรือไม่
    if (_state.selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกรูปภาพสินค้าอย่างน้อย 1 รูปก่อนเพิ่มประมูล'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'เลือกรูป',
            textColor: Colors.white,
            onPressed: () {
              _showImageSelectionDialog();
            },
          ),
        ),
      );
      return;
    }

    if (!_state.validateForm()) {
      return;
    }

    // Validate using service
    final validation = _state.validateAuctionData();
    if (!validation['isValid']) {
      final errors = validation['errors'] as Map<String, String>;
      final errorMessage = errors.values.join('\n');
      AddAuctionMethods.showErrorDialog(context, errorMessage);
      return;
    }

    final confirmed = await AddAuctionMethods.showConfirmationDialog(context);
    if (!confirmed) {
      return;
    }

    _state.updateSubmittingState(true);
    setState(() {});

    try {
      final auctionData = await _state.getFormattedAuctionData();
      final result = await AddAuctionMethods.saveAuction(
        auctionData: auctionData,
        imageFiles: _state.selectedImages,
      );

      if (result['status'] == 'success') {
        AddAuctionMethods.showSuccessDialog(context);
        _state.resetForm();
      } else {
        AddAuctionMethods.showErrorDialog(
            context, result['message'] ?? 'เกิดข้อผิดพลาด');
      }
    } catch (e) {
      AddAuctionMethods.showErrorDialog(context, 'เกิดข้อผิดพลาด: $e');
    } finally {
      _state.updateSubmittingState(false);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มประมูล'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showRelistDialog,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.repeat,
                color: Colors.green[700],
                size: 20,
              ),
            ),
            tooltip: 'ลงซ้ำจากสินค้าเก่า',
          ),
          IconButton(
            onPressed: () {
              _showAdminContactDialog(context);
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.headset_mic,
                color: Colors.blue[700],
                size: 20,
              ),
            ),
            tooltip: 'ข้อมูลติดต่อ Admin',
          ),
        ],
      ),
      body: Form(
        key: _state.formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Relist Button Banner
              // Container(
              //   margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              //   child: ElevatedButton.icon(
              //     onPressed: _showRelistDialog,
              //     icon: Icon(Icons.repeat, color: Colors.white),
              //     label: Text(
              //       'ลงซ้ำจากสินค้าเก่า',
              //       style: TextStyle(
              //         fontSize: 16,
              //         fontWeight: FontWeight.bold,
              //         color: Colors.white,
              //       ),
              //     ),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.green[600],
              //       padding: const EdgeInsets.symmetric(vertical: 16),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       elevation: 2,
              //     ),
              //   ),
              // ),

              // Promotion Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'โปรโมชั่นพิเศษ!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ค่าธรรมเนียมเพียง 2% จากยอดชนะ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PromotionPolicyPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ดูรายละเอียด',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Image Section
              AddAuctionWidgets.buildImageSection(
                selectedImages: _state.selectedImages,
                onPickImage: _pickImage,
                onTakePhoto: _takePhoto,
                onRemoveImage: _removeImage,
              ),

              // Quotation Type Dropdown
              AddAuctionWidgets.buildQuotationTypeDropdown(
                quotationTypes: _state.quotationTypes,
                isLoadingQuotationTypes: _state.isLoadingQuotationTypes,
                selectedQuotationTypeId: _state.selectedQuotationTypeId,
                selectedQuotationTypeName: _state.selectedQuotationTypeName,
                onQuotationTypeChanged: _updateQuotationType,
              ),
              // Product Info Section
              AddAuctionWidgets.buildTextField(
                label: 'ชื่อสินค้า *',
                controller: _state.productNameController,
                validator: (value) =>
                    AddAuctionMethods.validateRequired(value, 'ชื่อสินค้า'),
              ),

              // Date Section
              AddAuctionWidgets.buildDateSection(
                startDate: _state.startDate,
                endDate: _state.endDate,
                onSelectStartDate: () => _selectDate(context, true),
                onSelectEndDate: () => _selectDate(context, false),
              ),
              AddAuctionWidgets.buildTextField(
                label: 'รายละเอียดสินค้า *',
                controller: _state.descriptionController,
                maxLines: 3,
                validator: (value) => AddAuctionMethods.validateRequired(
                    value, 'รายละเอียดสินค้า'),
              ),
              AddAuctionWidgets.buildTextField(
                label: 'หมายเหตุ (ถ้ามี)',
                controller: _state.notesController,
                maxLines: 2,
                validator: (value) => null, // Optional
              ),

              // Delivery Section
              AddAuctionWidgets.buildDeliverySection(
                deliveryType: _state.deliveryType,
                deliveryPriceController: _state.deliveryPriceController,
                deliveryDistanceController: _state.deliveryDistanceController,
                deliveryPricePerKmController: _state.deliveryPricePerKmController,
                onDeliveryTypeChanged: (value) {
                  _state.deliveryType = value;
                  setState(() {});
                },
                onDeliveryPriceChanged: (value) {
                  setState(() {});
                },
                onDeliveryDistanceChanged: (value) {
                  setState(() {});
                },
                onDeliveryPricePerKmChanged: (value) {
                  setState(() {});
                },
              ),

              // Quantity Fields for AS03 - Hidden
              // if (_state.selectedQuotationTypeCode == 'AS03')
              //   AddAuctionWidgets.buildQuantityFields(
              //     maxQuantityController: _state.maxQuantityController,
              //     currentQuantityController: _state.currentQuantityController,
              //   ),

              // Combined Price Section
              AddAuctionWidgets.buildCombinedPriceSection(
                startingPriceController: _state.startingPriceController,
                minIncrementController: _state.minIncrementController,
                isPercentage: _state.isPercentage,
                percentageValue: _state.percentageValue,
                currentPrice: _state.getCurrentPrice(),
                hasStartingPrice: _state.getCurrentPrice() > 0,
                onStartingPriceChanged: (value) {
                  // อัปเดตราคาปัจจุบันเมื่อราคาเริ่มต้นเปลี่ยน
                  final currentPrice = _state.getCurrentPrice();
                  final minIncrement = _state.getMinIncrement();

                  // ถ้าขั้นต่ำการเพิ่มเกินราคาปัจจุบัน ให้ reset เป็น 0
                  if (minIncrement > currentPrice && currentPrice > 0) {
                    _state.minIncrementController.clear();
                  }

                  setState(() {});
                },
                onMinIncrementChanged: (value) {
                  // อัปเดตขั้นต่ำการเพิ่มเมื่อจำนวนเงินคงที่เปลี่ยน
                  setState(() {});
                },
                onPercentageChanged: _updatePercentageMode,
                onPercentageValueChanged: _updatePercentageValue,
                // เพิ่ม parameters สำหรับการคำนวณราคา
                costPriceController: _state.costPriceController,
                quantityController: _state.quantityController,
                onCostPriceChanged: (value) {
                  setState(() {});
                },
                onQuantityChanged: (value) {
                  setState(() {});
                },
                context: context,
                showCostCalculation: _state.showCostCalculation,
                onShowCostCalculationChanged: (show) {
                  _state.updateShowCostCalculation(show);
                  setState(() {});
                },
              ),

              // Bidder Count Section
              // AddAuctionWidgets.buildBidderCountSection(
              //   bidderCount: 0,
              //   onBidderCountChanged: (value) {}, // ไม่ใช้ callback
              // ),

              // Seller Info Section
              // AddAuctionWidgets.buildSellerInfoSection(
              //   sellerNameController: _state.sellerNameController,
              //   sellerPhoneController: _state.sellerPhoneController,
              // ),

              // Submit Button
              Container(
                margin: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_state.isSubmitting || _state.selectedImages.isEmpty) ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _state.selectedImages.isEmpty ? Colors.grey : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _state.isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('กำลังเพิ่มประมูล...'),
                          ],
                        )
                      : Text(
                          _state.selectedImages.isEmpty ? 'กรุณาเลือกรูปภาพก่อน' : 'เพิ่มประมูล',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
