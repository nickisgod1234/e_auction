import 'package:flutter/material.dart';
import 'package:e_auction/views/first_page/detail_page/detail_page.dart';
import 'package:intl/intl.dart';

class MyAuctionsPage extends StatefulWidget {
  const MyAuctionsPage({super.key});

  @override
  State<MyAuctionsPage> createState() => _MyAuctionsPageState();
}

class _MyAuctionsPageState extends State<MyAuctionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  // Mock data for user's auction history
  final List<Map<String, dynamic>> _activeBids = [
    {
      'id': 'rolex_submariner_001',
      'title': 'Rolex Submariner',
      'myBid': 850000,
      'currentPrice': 860000,
      'timeRemaining': 'เหลือ 2:30:45',
      'image': 'assets/images/m126618lb-0002.png',
      'status': 'active', // active, outbid, winning
      'bidCount': 12,
      'myBidRank': 2, // ตำแหน่งการประมูลของฉัน
    },
    {
      'id': 'iphone_15_pro_max_002',
      'title': 'iPhone 15 Pro Max',
      'myBid': 45000,
      'currentPrice': 45000,
      'timeRemaining': 'เหลือ 1:15:30',
      'image': 'assets/images/4ebcdc_032401a646044297adbcf3438498a19b~mv2.png',
      'status': 'winning',
      'bidCount': 8,
      'myBidRank': 1,
    },
    {
      'id': 'hermes_birkin_005',
      'title': 'Hermès Birkin Bag',
      'myBid': 250000,
      'currentPrice': 255000,
      'timeRemaining': 'เหลือ 4:20:10',
      'image': 'assets/images/db10cd_5d78534c69064ecebbef175602c6bfe0~mv2.png',
      'status': 'outbid',
      'bidCount': 20,
      'myBidRank': 3,
    },
  ];

  final List<Map<String, dynamic>> _wonAuctions = [
    {
      'id': 'cartier_santos_010',
      'title': 'Cartier Santos',
      'finalPrice': 680000,
      'myBid': 680000,
      'completedDate': '2 วันที่แล้ว',
      'image': 'assets/images/wssa0063-cartier-santos-de-cartier-medium-model-car0356037.png',
      'status': 'won',
      'sellerName': 'Luxury Timepieces',
      'paymentStatus': 'paid', // paid, pending, overdue
      'auctionId': 'AUCT-2025-010',
    },
    {
      'id': 'apple_watch_ultra_011',
      'title': 'Apple Watch Ultra',
      'finalPrice': 32000,
      'myBid': 32000,
      'completedDate': '1 วันที่แล้ว',
      'image': 'assets/images/noimage.jpg',
      'status': 'won',
      'sellerName': 'Apple Store Thailand',
      'paymentStatus': 'pending',
      'auctionId': 'AUCT-2025-011',
    },
  ];

  final List<Map<String, dynamic>> _lostAuctions = [
    {
      'id': 'patek_nautilus_006',
      'title': 'Patek Philippe Nautilus',
      'finalPrice': 1500000,
      'myBid': 1450000,
      'completedDate': '3 วันที่แล้ว',
      'image': 'assets/images/The-ultimative-Patek-Philippe-Nautilus-Guide.jpg',
      'status': 'lost',
      'winnerBid': 1500000,
      'sellerName': 'Luxury Watches',
    },
    {
      'id': 'tesla_model_s_007',
      'title': 'Tesla Model S',
      'finalPrice': 3500000,
      'myBid': 3400000,
      'completedDate': '5 วันที่แล้ว',
      'image': 'assets/images/testlamodels.png',
      'status': 'lost',
      'winnerBid': 3500000,
      'sellerName': 'Tesla Thailand',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'winning':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'outbid':
        return Colors.orange;
      case 'won':
        return Colors.green;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'winning':
        return 'กำลังชนะ';
      case 'active':
        return 'กำลังประมูล';
      case 'outbid':
        return 'ถูกแซง';
      case 'won':
        return 'ชนะการประมูล';
      case 'lost':
        return 'แพ้การประมูล';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Widget _buildActiveBidCard(Map<String, dynamic> auction) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            auction['image'],
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
              );
            },
          ),
        ),
        title: Text(
          auction['title'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('การประมูลของฉัน: ฿${NumberFormat('#,###').format(auction['myBid'])}'),
            Text('ราคาปัจจุบัน: ฿${NumberFormat('#,###').format(auction['currentPrice'])}'),
            Text('${auction['timeRemaining']} • อันดับที่ ${auction['myBidRank']}'),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(auction['status']),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(auction['status']),
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(auctionData: auction),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWonAuctionCard(Map<String, dynamic> auction) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            auction['image'],
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
              );
            },
          ),
        ),
        title: Text(
          auction['title'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ราคาสุดท้าย: ฿${NumberFormat('#,###').format(auction['finalPrice'])}'),
            Text('${auction['completedDate']} • ${auction['sellerName']}'),
            Text(
              'เลขที่ประมูล: ${auction['auctionId']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
            Text(
              auction['paymentStatus'] == 'paid' ? 'ชำระเงินแล้ว' : 'รอชำระเงิน',
              style: TextStyle(
                color: auction['paymentStatus'] == 'paid' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (auction['paymentStatus'] == 'pending')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(context, auction),
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('ชำระเงิน'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'ชนะ',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPage(auctionData: auction),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLostAuctionCard(Map<String, dynamic> auction) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            auction['image'],
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
              );
            },
          ),
        ),
        title: Text(
          auction['title'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('การประมูลของฉัน: ฿${NumberFormat('#,###').format(auction['myBid'])}'),
            Text('ราคาที่ชนะ: ฿${NumberFormat('#,###').format(auction['winnerBid'])}'),
            Text('${auction['completedDate']} • ${auction['sellerName']}'),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'แพ้',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Map<String, dynamic> auction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ชำระเงิน'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'ยินดีด้วย! คุณชนะการประมูล',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('สินค้า', auction['title']),
              _buildInfoRow('เลขที่ประมูล', auction['auctionId'], isMonospace: true),
              _buildInfoRow('ราคาที่ชนะ', '฿${NumberFormat('#,###').format(auction['finalPrice'])}', isHighlight: true),
              const SizedBox(height: 16),
              const Text(
                'กรุณาติดต่อผู้ขายเพื่อชำระเงิน:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildContactRow(Icons.phone, 'โทร: 02-123-4567'),
              _buildContactRow(Icons.chat, 'Line: @e_auction_support'),
              _buildContactRow(Icons.email, 'Email: support@e-auction.com'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Text(
                  '💡 อย่าลืมแจ้งเลขที่ประมูลเมื่อติดต่อผู้ขาย',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ส่งข้อความติดต่อผู้ขายแล้ว (${auction['auctionId']})'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              icon: const Icon(Icons.message, size: 16),
              label: const Text('ติดต่อผู้ขาย'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
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
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? Colors.green : Colors.black,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            contact,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการประมูลของฉัน'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(
                  text: 'กำลังประมูล (${_activeBids.length})',
                ),
                Tab(
                  text: 'ชนะแล้ว (${_wonAuctions.length})',
                ),
                Tab(
                  text: 'แพ้แล้ว (${_lostAuctions.length})',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active Bids Tab
                _activeBids.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gavel, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'ไม่มีรายการที่กำลังประมูล',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _activeBids.length,
                        itemBuilder: (context, index) {
                          return _buildActiveBidCard(_activeBids[index]);
                        },
                      ),
                
                // Won Auctions Tab
                _wonAuctions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'ยังไม่มีรายการที่ชนะ',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _wonAuctions.length,
                        itemBuilder: (context, index) {
                          return _buildWonAuctionCard(_wonAuctions[index]);
                        },
                      ),
                
                // Lost Auctions Tab
                _lostAuctions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'ยังไม่มีรายการที่แพ้',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _lostAuctions.length,
                        itemBuilder: (context, index) {
                          return _buildLostAuctionCard(_lostAuctions[index]);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 