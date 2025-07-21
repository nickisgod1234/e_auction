import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_auction/utils/format.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> auctionData;

  const DetailPage({
    super.key,
    required this.auctionData,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isFavorite = false;
  int _currentBid = 0;
  int _minBidIncrement = 0;
  final TextEditingController _bidController = TextEditingController();
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    // แก้ไข type casting เพื่อรองรับทั้ง int และ double จาก API
    final currentPrice = widget.auctionData['currentPrice'];
    if (currentPrice is double) {
      _currentBid = currentPrice.round();
    } else if (currentPrice is int) {
      _currentBid = currentPrice;
    } else {
      _currentBid = 0;
    }

    final startingPrice = widget.auctionData['startingPrice'];
    int startingPriceInt = 0;
    if (startingPrice is double) {
      startingPriceInt = startingPrice.round();
    } else if (startingPrice is int) {
      startingPriceInt = startingPrice;
    }

    // คำนวณจำนวนเงินขั้นต่ำที่ต้องเพิ่ม (3% ของราคาเริ่มต้น)
    _minBidIncrement = (startingPriceInt * 0.03).round();
    // ตั้งค่าเริ่มต้นให้กับ text field เป็นราคาปัจจุบัน + ขั้นต่ำที่ต้องเพิ่ม
    _bidController.text = (_currentBid + _minBidIncrement).toString();
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  // Helper method to get starting price as int
  int _getStartingPriceAsInt() {
    final startingPriceRaw = widget.auctionData['startingPrice'];
    if (startingPriceRaw is double) {
      return startingPriceRaw.round();
    } else if (startingPriceRaw is int) {
      return startingPriceRaw;
    }
    return 850000; // default value
  }

  void _placeBid() async {
    final bidAmount = int.tryParse(_bidController.text) ?? 0;
    if (bidAmount <= _currentBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ราคาประมูลต้องสูงกว่าราคาปัจจุบัน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final increment = bidAmount - _currentBid;
    if (increment < _minBidIncrement) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'ต้องเพิ่มขั้นต่ำ ฿${Format.formatCurrency(_minBidIncrement)} (3% ของราคาเริ่มต้น)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ตรวจสอบว่าควรแสดง dialog หรือไม่ (แยกตาม ID ของสินค้า)
    final prefs = await SharedPreferences.getInstance();
    final itemId = widget.auctionData['id'] ?? 'default';
    final dontShowDialog =
        prefs.getBool('dont_show_bid_dialog_$itemId') ?? false;

    if (dontShowDialog) {
      // ไม่แสดง dialog และประมูลทันที
      _confirmBid(bidAmount);
    } else {
      // แสดง popup ก่อนประมูล
      _showBidConfirmationDialog(bidAmount);
    }
  }

  void _showBidConfirmationDialog(int bidAmount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.gavel,
                    color: context.customTheme.primaryColor,
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ยืนยันการประมูล',
                    style: TextStyle(
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
                    'คุณต้องการประมูลสินค้านี้ในราคา:',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.customTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '฿${Format.formatCurrency(bidAmount)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.customTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ข้อกำหนดการประมูล',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• การประมูลสินค้าชิ้นนี้จะเพิ่มครั้งละ 3% จากยอดเริ่มต้น\n• ราคาเริ่มต้น: ${Format.formatCurrency(_getStartingPriceAsInt())}\n• เพิ่มขั้นต่ำ: ${Format.formatCurrency(_minBidIncrement)}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _dontShowAgain,
                        onChanged: (value) {
                          setState(() {
                            _dontShowAgain = value ?? false;
                          });
                        },
                        activeColor: context.customTheme.primaryColor,
                      ),
                      Expanded(
                        child: Text(
                          'ไม่ต้องแสดงข้อความนี้อีก',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // บันทึกการตั้งค่า checkbox (แยกตาม ID ของสินค้า)
                    if (_dontShowAgain) {
                      final prefs = await SharedPreferences.getInstance();
                      final itemId = widget.auctionData['id'] ?? 'default';
                      await prefs.setBool('dont_show_bid_dialog_$itemId', true);
                    }

                    Navigator.of(context).pop();
                    _confirmBid(bidAmount);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.customTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('ยืนยันประมูล'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmBid(int bidAmount) {
    setState(() {
      _currentBid = bidAmount;
      // อัพเดทค่าใน text field เป็นราคาปัจจุบัน + ขั้นต่ำที่ต้องเพิ่ม
      _bidController.text = (_currentBid + _minBidIncrement).toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('ประมูลสำเร็จ! ราคา: ฿${Format.formatCurrency(bidAmount)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Helper method to build auction image
  Widget _buildAuctionImage(String? imagePath,
      {double? width, double? height}) {
    if (imagePath == null || imagePath.isEmpty) {
      return Image.asset('assets/images/noimage.jpg',
          width: width, height: height, fit: BoxFit.cover);
    }

    // ตรวจสอบว่าเป็น URL หรือไม่
    final isUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isUrl) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/noimage.jpg',
              width: width, height: height, fit: BoxFit.cover);
        },
      );
    } else {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/images/noimage.jpg',
              width: width, height: height, fit: BoxFit.cover);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดสินค้า'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.share,
              color: Colors.grey,
            ),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'reset_dialog') {
                final prefs = await SharedPreferences.getInstance();
                final itemId = widget.auctionData['id'] ?? 'default';
                await prefs.remove('dont_show_bid_dialog_$itemId');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('รีเซ็ตการตั้งค่าเรียบร้อย'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset_dialog',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('รีเซ็ตการตั้งค่า Dialog'),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  _buildAuctionImage(
                    widget.auctionData['image'],
                    width: double.infinity,
                    height: 300,
                  ),
                  // Auction Status Badge และประเภทสินค้า
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ป้ายสถานะ
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.auctionData['isActive'] == true
                                ? Colors.green
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.auctionData['isActive'] == true
                                ? 'กำลังประมูล'
                                : 'กำลังจะเริ่ม',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        // ป้ายประเภทสินค้า
                        if (widget.auctionData['quotation_type_description'] != null && 
                            widget.auctionData['quotation_type_description'].toString().isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  widget.auctionData['quotation_type_description'].toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Time Remaining
                  if (widget.auctionData['isActive'] == true)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              widget.auctionData['timeRemaining'] ?? '2:30:45',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Details
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title
                  Text(
                    widget.auctionData['title'] ?? 'Rolex Submariner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Current Price
                  Row(
                    children: [
                      Text(
                        'ราคาปัจจุบัน: ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${Format.formatCurrency(_currentBid)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.customTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Starting Price
                  Text(
                    'ราคาเริ่มต้น: ${Format.formatCurrency(_getStartingPriceAsInt())}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),

                  // Minimum Bid Increment
                  Text(
                    'ขั้นต่ำ: ${Format.formatCurrency(widget.auctionData['minimum_increase'] ?? 100)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Bid Count
                  Row(
                    children: [
                      Icon(Icons.gavel, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        '${widget.auctionData['bidCount'] ?? 12} รายการประมูล',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Product Description
                  Text(
                    'รายละเอียดสินค้า',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.auctionData['description'] ??
                        'นาฬิกา Rolex Submariner รุ่นคลาสสิก วัสดุคุณภาพสูง มาพร้อมกับกล่องและเอกสารรับประกัน อยู่ในสภาพดีมาก เหมาะสำหรับนักสะสมและผู้ที่ชื่นชอบนาฬิกาคุณภาพสูง',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Specifications
                  Text(
                    'ข้อมูลจำเพาะ',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildSpecificationItem(
                      'ยี่ห้อ', widget.auctionData['brand'] ?? 'Rolex'),
                  _buildSpecificationItem(
                      'รุ่น', widget.auctionData['model'] ?? 'Submariner'),
                  _buildSpecificationItem(
                      'วัสดุ', widget.auctionData['material'] ?? 'สแตนเลสสตีล'),
                  _buildSpecificationItem(
                      'ขนาด', widget.auctionData['size'] ?? '40mm'),
                  _buildSpecificationItem(
                      'สี', widget.auctionData['color'] ?? 'ดำ'),
                  _buildSpecificationItem(
                      'สภาพ', widget.auctionData['condition'] ?? 'ดีมาก'),
                  SizedBox(height: 24),

                  // Item Notes
                  _buildItemNotes(),
                  SizedBox(height: 24),

                  // Seller Information
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ข้อมูลผู้ขาย',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: context.customTheme.primaryColor,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.auctionData['sellerName'] ??
                                      'CloudmateTH',
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'คะแนน: ${widget.auctionData['sellerRating'] ?? '4.8'} ⭐',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.auctionData['isActive'] == true
          ? SafeArea(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bidController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'ใส่ราคาประมูล',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixText: '฿',
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _placeBid,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.customTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('ประมูล'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSpecificationItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemNotes() {
    final itemNote = widget.auctionData['item_note'];
    if (itemNote == null || itemNote.toString().isEmpty) {
      // แสดงหมายเหตุทดสอบเพื่อดูว่า section ทำงานหรือไม่
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.note, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'หมายเหตุ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.note, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'หมายเหตุ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  itemNote.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
