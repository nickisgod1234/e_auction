import 'package:flutter/material.dart';
import 'package:e_auction/services/winner_service.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/views/first_page/widgets/auction_image_widget.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';

class WinnerManagementPage extends StatefulWidget {
  const WinnerManagementPage({super.key});

  @override
  State<WinnerManagementPage> createState() => _WinnerManagementPageState();
}

class _WinnerManagementPageState extends State<WinnerManagementPage> {
  List<Map<String, dynamic>> _winners = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWinners();
  }

  Future<void> _loadWinners() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await WinnerService.getAllWinners();
      List<dynamic> winnersList = [];
      
      // ดึงข้อมูลจาก result - getAllWinners() จะ return Map<String, dynamic>
      if (result.containsKey('data') && result['data'] != null) {
        final data = result['data'];
        if (data is List) {
          winnersList = data;
        }
      } else if (result.containsKey('status') && result['status'] == 'success' && result['data'] != null) {
        final data = result['data'];
        if (data is List) {
          winnersList = data;
        }
      }
      
      // กรองเฉพาะ status = "announced"
      final announcedWinners = winnersList.where((winner) {
        final status = winner['status']?.toString() ?? '';
        return status.toLowerCase() == 'announced';
      }).toList();
      
      // แปลงข้อมูลเป็นรูปแบบที่ใช้ในแอป และเพิ่มรูปภาพ
      final convertedWinners = WinnerService.convertWinnersToAppFormat(announcedWinners);
      
      // เพิ่มรูปภาพให้แต่ละ winner จาก raw data
      for (int i = 0; i < convertedWinners.length && i < announcedWinners.length; i++) {
        final rawWinner = announcedWinners[i];
        final images = _parseQuotationImages(rawWinner['quotation_image']);
        convertedWinners[i]['images'] = images;
        convertedWinners[i]['quotation_image'] = rawWinner['quotation_image']; // เก็บ raw data ไว้ด้วย
      }
      
      setState(() {
        _winners = convertedWinners;
      });
    } catch (e) {
      print('Error loading winners: $e');
      _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
      setState(() {
        _winners = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredWinners {
    var filtered = _winners;

    // กรองตามคำค้นหา
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((winner) {
        final description = winner['description']?.toString().toLowerCase() ?? 
                           winner['title']?.toString().toLowerCase() ?? '';
        final winnerName = winner['winnerBidderName']?.toString().toLowerCase() ?? 
                          winner['winnerName']?.toString().toLowerCase() ?? '';
        final auctionId = winner['auctionId']?.toString().toLowerCase() ?? '';
        
        return description.contains(query) ||
               winnerName.contains(query) ||
               auctionId.contains(query);
      }).toList();
    }

    return filtered;
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) {
      return 'ไม่ระบุ';
    }
    
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd/MM/yyyy HH:mm', 'th').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  // Parse quotation_image array และสร้าง URL สำหรับรูปภาพ
  List<String> _parseQuotationImages(dynamic quotationImage) {
    List<String> imageUrls = [];
    
    if (quotationImage == null) {
      return imageUrls;
    }
    
    try {
      dynamic imageData = quotationImage;
      
      // ถ้าเป็น String ให้ลอง parse เป็น JSON
      if (imageData is String) {
        String imageString = imageData.trim();
        
        // ลบ quotes นอกสุดถ้ามี
        if (imageString.startsWith('"') && imageString.endsWith('"')) {
          imageString = imageString.substring(1, imageString.length - 1);
          imageString = imageString.replaceAll('\\"', '"').replaceAll('\\\\', '\\');
        }
        
        // ลอง parse JSON หลายครั้ง
        if (imageString.startsWith('[') && imageString.endsWith(']')) {
          dynamic parsed = imageString;
          for (int i = 0; i < 3; i++) {
            try {
              if (parsed is String) {
                parsed = jsonDecode(parsed);
              } else {
                break;
              }
            } catch (e) {
              break;
            }
          }
          imageData = parsed;
        }
      }
      
      // ถ้าเป็น List ให้แปลงเป็น URL
      if (imageData is List) {
        int count = 0;
        for (var img in imageData) {
          if (count >= 5) break; // ไม่เกิน 5 ภาพ
          
          if (img != null && img.toString().isNotEmpty) {
            String imgName = img.toString()
                .replaceAll('"', '')
                .replaceAll('\\', '')
                .trim();
            
            if (imgName.isNotEmpty) {
              final imageUrl = _buildImageUrl(imgName);
              if (imageUrl != 'assets/images/noimage.jpg' || imageUrls.isEmpty) {
                imageUrls.add(imageUrl);
                count++;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing quotation_image: $e');
    }
    
    // ถ้าไม่มีรูปเลย ให้ใช้ noimage.jpg
    if (imageUrls.isEmpty) {
      imageUrls.add('assets/images/noimage.jpg');
    }
    
    return imageUrls;
  }

  // สร้าง URL สำหรับรูปภาพ
  String _buildImageUrl(String imageName) {
    if (imageName.isEmpty || 
        imageName == '[]' || 
        imageName == 'assets/images/noimage.jpg' ||
        imageName.startsWith('http://') ||
        imageName.startsWith('https://') ||
        imageName.startsWith('assets/')) {
      return imageName;
    }
    
    // ตรวจสอบนามสกุลไฟล์
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final hasValidExtension = validExtensions.any((ext) => 
        imageName.toLowerCase().endsWith(ext));
    
    if (!hasValidExtension) {
      return 'assets/images/noimage.jpg';
    }
    
    // สร้าง URL
    String baseUrl = 'https://cm-mecustomers.com/ERP-Cloudmate/modules/sales/uploads/quotation/$imageName';
    
    // แปลงเป็น HTTP สำหรับ Android
    if (Platform.isAndroid) {
      baseUrl = baseUrl.replaceFirst('https://', 'http://');
    }
    
    return baseUrl;
  }

  void _showWinnerDetails(Map<String, dynamic> winner) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'รายละเอียดผู้ชนะ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(),
                SizedBox(height: 16),
                
                // ข้อมูลสินค้า
                _buildDetailSection(
                  'ข้อมูลสินค้า',
                  [
                    _buildDetailRow('ชื่อสินค้า', winner['title'] ?? 'ไม่ระบุ'),
                    _buildDetailRow('รหัสการประมูล', winner['auctionId'] ?? 'ไม่ระบุ'),
                    _buildDetailRow('ราคาที่ชนะ', Format.formatCurrency(winner['finalPrice'] ?? 0)),
                    _buildDetailRow('วันที่สิ้นสุด', _formatDateTime(winner['auctionEndTime'])),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // ข้อมูลผู้ชนะ
                _buildDetailSection(
                  'ข้อมูลผู้ชนะ',
                  [
                    _buildDetailRow('ชื่อ-นามสกุล', winner['winnerName'] ?? 'ไม่ระบุ'),
                    _buildDetailRow('เบอร์โทรศัพท์', winner['winnerPhone'] ?? 'ไม่ระบุ'),
                    _buildDetailRow('อีเมล', winner['winnerEmail'] ?? 'ไม่ระบุ'),
                    _buildDetailRow('ที่อยู่', winner['winnerFullAddress'] ?? winner['winnerAddress'] ?? 'ไม่ระบุ'),
                    _buildDetailRow('วันที่ประกาศ', _formatDateTime(winner['winnerAnnouncedTime'])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ตรวจสอบผู้ชนะ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadWinners,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาด้วยชื่อสินค้า, ชื่อผู้ชนะ, เบอร์โทร, หรือรหัสการประมูล',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: 12),
                // Info Text
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'แสดงเฉพาะผู้ชนะที่ประกาศแล้ว (${_winners.length} รายการ)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Winners List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredWinners.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'ไม่พบข้อมูลผู้ชนะ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadWinners,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredWinners.length,
                          itemBuilder: (context, index) {
                            final winner = _filteredWinners[index];
                            return _buildWinnerCard(winner);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerCard(Map<String, dynamic> winner) {
    // ดึงข้อมูลจาก winner object โดยใช้ key ที่ตรงกับ API response
    final winnerBidderName = winner['winnerBidderName'] ?? 
                             winner['winnerName'] ?? 
                             'ไม่ระบุ';
    final winningAmount = winner['finalPrice'] ?? 
                         winner['winning_amount'] ?? 
                         0;
    final announcedAt = winner['winnerAnnouncedTime'] ?? 
                       winner['announced_at'] ?? 
                       '';
    final quotationDescription = winner['description'] ?? 
                                winner['quotationDescription'] ?? 
                                winner['title'] ?? 
                                winner['short_text'] ?? 
                                'ไม่ระบุ';
    final quantity = winner['quantity'] ?? '1';
    
    // ดึงรูปภาพ (ไม่เกิน 5 ภาพ)
    List<String> images = [];
    if (winner['images'] != null && winner['images'] is List) {
      images = List<String>.from(winner['images']);
    } else if (winner['quotation_image'] != null) {
      images = _parseQuotationImages(winner['quotation_image']);
    }
    
    // จำกัดไม่เกิน 5 ภาพ
    if (images.length > 5) {
      images = images.sublist(0, 5);
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showWinnerDetails(winner),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      color: Colors.amber[700],
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quotationDescription,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'จำนวน: $quantity',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ประกาศแล้ว',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              // รูปภาพ (ไม่เกิน 5 ภาพ)
              if (images.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(right: 8),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AuctionImageWidget(
                            imagePath: images[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              Divider(height: 24),
              
              // Winner Info - แสดงเฉพาะข้อมูลที่ต้องการ
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ผู้ชนะ: $winnerBidderName',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ราคาที่ชนะ: ${Format.formatCurrency(winningAmount)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ประกาศเมื่อ: ${_formatDateTime(announcedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

