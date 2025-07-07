import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:e_auction/views/first_page/widget_home_cm/current_auction_card.dart';
import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:intl/intl.dart';
import 'package:e_auction/utils/format.dart';

class CurrentAuctionPage extends StatelessWidget {
  CurrentAuctionPage({super.key});

  // Mock data for current auctions (ใช้ข้อมูลเดียวกับใน HomeScreen)
  final List<Map<String, dynamic>> _currentAuctions = [
    {
      'id': 'rolex_submariner_001',
      'title': 'Rolex Submarinฟหดฟดer',
      'currentPrice': 850000,
      'startingPrice': 800000,
      'bidCount': 12,
      'timeRemaining': 'เหลือ 2:30:45',
      'isActive': true,
      'image': 'assets/images/m126618lb-0002.png',
      'description': 'นาฬิกา Rolex Submariner รุ่นคลาสสิก วัสดุคุณภาพสูง มาพร้อมกับกล่องและเอกสารรับประกัน อยู่ในสภาพดีมาก',
      'brand': 'Rolex',
      'model': 'Submariner',
      'material': 'สแตนเลสสตีล',
      'size': '40mm',
      'color': 'ดำ',
      'condition': 'ดีมาก',
      'sellerName': 'ผู้ขายมืออาชีพ',
      'sellerRating': '4.8',
      'category': 'watches'
    },
    {
      'id': 'iphone_15_pro_max_002',
      'title': 'iPhone 15 Pro Max',
      'currentPrice': 45000,
      'startingPrice': 40000,
      'bidCount': 8,
      'timeRemaining': 'เหลือ 1:15:30',
      'isActive': true,
      'image': 'assets/images/4ebcdc_032401a646044297adbcf3438498a19b~mv2.png',
      'description': 'iPhone 15 Pro Max สี Titanium Natural 256GB สภาพใหม่',
      'brand': 'Apple',
      'model': 'iPhone 15 Pro Max',
      'material': 'Titanium',
      'size': '6.7 นิ้ว',
      'color': 'Titanium Natural',
      'condition': 'ใหม่',
      'sellerName': 'Apple Store Thailand',
      'sellerRating': '4.9',
      'category': 'phones'
    },
    {
      'id': 'macbook_pro_m3_003',
      'title': 'MacBook Pro M3',
      'currentPrice': 75000,
      'startingPrice': 70000,
      'bidCount': 15,
      'timeRemaining': 'เหลือ 3:45:20',
      'isActive': true,
      'image': 'assets/images/noimage.jpg',
      'description': 'MacBook Pro 14 นิ้ว พร้อมชิป M3 512GB SSD 16GB RAM อยู่ในสภาพดีมาก',
      'brand': 'Apple',
      'model': 'MacBook Pro M3',
      'material': 'Aluminum',
      'size': '14 นิ้ว',
      'color': 'Space Gray',
      'condition': 'ดีมาก',
      'sellerName': 'Tech Store',
      'sellerRating': '4.7',
      'category': 'computers'
    },
    {
      'id': 'sony_a7r_v_004',
      'title': 'Sony A7R V Camera',
      'currentPrice': 120000,
      'startingPrice': 110000,
      'bidCount': 6,
      'timeRemaining': 'เหลือ 0:30:15',
      'isActive': true,
      'image': 'assets/images/noimage.jpg',
      'description': 'กล้อง DSLR Sony A7R V 61MP มาพร้อมกับเลนส์ 24-70mm f/2.8 GM',
      'brand': 'Sony',
      'model': 'A7R V',
      'material': 'Magnesium Alloy',
      'size': 'Full Frame',
      'color': 'ดำ',
      'condition': 'ดีมาก',
      'sellerName': 'Camera Pro',
      'sellerRating': '4.6',
      'category': 'cameras'
    },
    {
      'id': 'hermes_birkin_005',
      'title': 'Hermès Birkin Bag',
      'currentPrice': 250000,
      'startingPrice': 200000,
      'bidCount': 20,
      'timeRemaining': 'เหลือ 4:20:10',
      'isActive': true,
      'image': 'assets/images/db10cd_5d78534c69064ecebbef175602c6bfe0~mv2.png',
      'description': 'กระเป๋า Hermès Birkin 30cm สี Black Togo Leather อยู่ในสภาพดีมาก',
      'brand': 'Hermès',
      'model': 'Birkin 30',
      'material': 'Togo Leather',
      'size': '30cm',
      'color': 'ดำ',
      'condition': 'ดีมาก',
      'sellerName': 'Luxury Collection',
      'sellerRating': '4.9',
      'category': 'bags'
    },
  ];

  // เพิ่มเมธอดสำหรับแสดง dialog ลงประมูล
  void _showBidDialog(BuildContext context, Map<String, dynamic> auctionData) {
    final TextEditingController bidController = TextEditingController();
    
    // แก้ไข type casting เพื่อรองรับทั้ง int และ double จาก API
    final currentPriceRaw = auctionData['currentPrice'];
    int currentPrice = 0;
    if (currentPriceRaw is double) {
      currentPrice = currentPriceRaw.round();
    } else if (currentPriceRaw is int) {
      currentPrice = currentPriceRaw;
    }
    
    final minBid = currentPrice + 1000; // ราคาขั้นต่ำเพิ่มขึ้น 1,000 บาท
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Icon(Icons.gavel, color: Colors.green, size: 48),
              SizedBox(height: 12),
              Text(
                'ลงประมูล',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                auctionData['title'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'ราคาปัจจุบัน: ${Format.formatCurrency(currentPrice)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'ราคาขั้นต่ำ: ${Format.formatCurrency(minBid)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: bidController,
                decoration: InputDecoration(
                  labelText: 'ราคาที่ต้องการประมูล (บาท)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixText: '฿',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final bidAmount = double.tryParse(bidController.text);
                if (bidAmount == null || bidAmount < minBid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('กรุณากรอกราคาที่ไม่ต่ำกว่า ${Format.formatCurrency(minBid)}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // จำลองการส่งข้อมูลไปยัง API
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ลงประมูลสำเร็จ! ราคา ฿${bidAmount.toStringAsFixed(0)}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('ยืนยัน', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'รายการประมูลที่กำลังดำเนินอยู่',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _currentAuctions.isEmpty
          ? Center(
              child: Text(
                'ไม่มีรายการที่กำลังประมูล',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _currentAuctions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            auctionData: _currentAuctions[index],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image and Timer
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.asset(
                                  _currentAuctions[index]['image'],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading image: ${_currentAuctions[index]['image']}');
                                    return Container(
                                      height: 200,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        _currentAuctions[index]['timeRemaining'],
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
                          // Details
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentAuctions[index]['title'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ราคาปัจจุบัน',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          Format.formatCurrency(_currentAuctions[index]['currentPrice']),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: context.customTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_currentAuctions[index]['bidCount']} รายการ',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                // เพิ่มปุ่มลงประมูล
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showBidDialog(context, _currentAuctions[index]),
                                    icon: Icon(Icons.gavel, color: Colors.white),
                                    label: Text('ลงประมูล'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
} 