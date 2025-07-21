import 'package:flutter/material.dart';
import 'package:e_auction/services/product_service.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:e_auction/views/first_page/auction_page/quantity_reduction_auction_detail_page.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:intl/intl.dart';

class QuantityReductionAuctionsPage extends StatefulWidget {
  const QuantityReductionAuctionsPage({super.key});

  @override
  State<QuantityReductionAuctionsPage> createState() => _QuantityReductionAuctionsPageState();
}

class _QuantityReductionAuctionsPageState extends State<QuantityReductionAuctionsPage> {
  late ProductService _productService;
  List<Map<String, dynamic>> _auctions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'current', 'upcoming', 'completed'

  @override
  void initState() {
    super.initState();
    _productService = ProductService(baseUrl: Config.apiUrlAuction);
    _loadQuantityReductionAuctions();
  }

  Future<void> _loadQuantityReductionAuctions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allAuctions = await _productService.getAllAuctionProducts();
      
      if (allAuctions != null) {
        // กรองเฉพาะ AS03 (การประมูลแบบลดจำนวน)
        final as03Auctions = allAuctions.where((auction) {
          final typeCode = auction['quotation_type_code']?.toString() ?? '';
          return typeCode == 'AS03';
        }).toList();

        // แปลงข้อมูลเป็นรูปแบบแอพ
        final formattedAuctions = as03Auctions.map((auction) {
          return _productService.convertToAppFormat(auction);
        }).toList();

        setState(() {
          _auctions = formattedAuctions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _auctions = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ไม่สามารถโหลดข้อมูลการประมูลแบบลดจำนวนได้';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredAuctions() {
    if (_selectedFilter == 'all') {
      return _auctions;
    }

    final now = DateTime.now();
    return _auctions.where((auction) {
      final startDate = DateTime.tryParse(auction['auction_start_date'] ?? '');
      final endDate = DateTime.tryParse(auction['auction_end_date'] ?? '');
      
      if (startDate == null || endDate == null) return false;

      switch (_selectedFilter) {
        case 'current':
          return now.isAfter(startDate) && now.isBefore(endDate);
        case 'upcoming':
          return now.isBefore(startDate);
        case 'completed':
          return now.isAfter(endDate);
        default:
          return true;
      }
    }).toList();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'current':
        return 'กำลังประมูล';
      case 'upcoming':
        return 'ยังไม่เริ่ม';
      case 'completed':
        return 'จบแล้ว';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'current':
        return Colors.green;
      case 'upcoming':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAuctionCard(Map<String, dynamic> auction) {
    final status = auction['status'] ?? 'unknown';
    final quantity = auction['quantity'] ?? 0;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                              builder: (context) => QuantityReductionAuctionDetailPage(auctionData: auction),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปภาพสินค้า
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 200,
                width: double.infinity,
                child: _buildAuctionImage(auction['image']),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ชื่อสินค้า
                  Text(
                    auction['title'] ?? 'ไม่ระบุชื่อสินค้า',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 8),
                  
                  // จำนวนสินค้า (สำคัญสำหรับ AS03)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: Colors.blue,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'จำนวน: $quantity รายการ',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // ราคา
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ราคาปัจจุบัน',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '฿${NumberFormat('#,###').format(auction['currentPrice'] ?? 0)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ราคาเริ่มต้น',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '฿${NumberFormat('#,###').format(auction['startingPrice'] ?? 0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // สถานะและเวลา
                  Row(
                    children: [
                      // สถานะ
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      
                      Spacer(),
                      
                      // เวลาที่เหลือ
                      if (status == 'current')
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              color: Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              auction['timeRemaining'] ?? 'ไม่ทราบเวลา',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      
                      if (status == 'upcoming')
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Colors.blue,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              auction['timeUntilStart'] ?? 'ไม่ทราบเวลา',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  // จำนวนผู้ประมูล
                  if (auction['bidCount'] != null && auction['bidCount'] > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${auction['bidCount']} คนประมูล',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
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
      ),
    );
  }

  Widget _buildAuctionImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 8),
              Text(
                'ไม่มีรูปภาพ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8),
                Text(
                  'ไม่สามารถโหลดรูปภาพ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('all', 'ทั้งหมด'),
          _buildFilterChip('current', 'กำลังประมูล'),
          _buildFilterChip('upcoming', 'ยังไม่เริ่ม'),
          _buildFilterChip('completed', 'จบแล้ว'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: context.customTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: context.customTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? context.customTheme.primaryColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAuctions = _getFilteredAuctions();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'การประมูลแบบลดจำนวน',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadQuantityReductionAuctions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          
          SizedBox(height: 8),
          
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'กำลังโหลดข้อมูลการประมูลแบบลดจำนวน...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadQuantityReductionAuctions,
                              child: Text('ลองใหม่'),
                            ),
                          ],
                        ),
                      )
                    : filteredAuctions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'ไม่พบการประมูลแบบลดจำนวน',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'ลองเปลี่ยนตัวกรองหรือรอสักครู่',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadQuantityReductionAuctions,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              itemCount: filteredAuctions.length,
                              itemBuilder: (context, index) {
                                return _buildAuctionCard(filteredAuctions[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
} 