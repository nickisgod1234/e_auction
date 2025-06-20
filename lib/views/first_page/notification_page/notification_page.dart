import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notification data
    final List<Map<String, dynamic>> notifications = [
      {
        'id': '1',
        'type': 'auction_won',
        'title': 'คุณชนะการประมูล!',
        'message': 'คุณชนะการประมูล Rolex Submariner กรุณาติดต่อเพื่อชำระเงิน',
        'auctionTitle': 'Rolex Submariner',
        'auctionId': 'AUCT-2025-001',
        'finalPrice': 850000,
        'image': 'assets/images/m126618lb-0002.png',
        'timestamp': '2 นาทีที่แล้ว',
        'isRead': false,
        'action': 'ชำระเงิน',
      },
      {
        'id': '2',
        'type': 'auction_won',
        'title': 'คุณชนะการประมูล!',
        'message': 'คุณชนะการประมูล iPhone 15 Pro Max กรุณาติดต่อเพื่อชำระเงิน',
        'auctionTitle': 'iPhone 15 Pro Max',
        'auctionId': 'AUCT-2025-002',
        'finalPrice': 45000,
        'image': 'assets/images/4ebcdc_032401a646044297adbcf3438498a19b~mv2.png',
        'timestamp': '1 ชั่วโมงที่แล้ว',
        'isRead': false,
        'action': 'ชำระเงิน',
      },
      {
        'id': '3',
        'type': 'auction_outbid',
        'title': 'คุณถูกแซงราคา',
        'message': 'มีผู้เสนอราคาสูงกว่าคุณใน MacBook Pro M3',
        'auctionTitle': 'MacBook Pro M3',
        'auctionId': 'AUCT-2025-003',
        'currentPrice': 76000,
        'image': 'assets/images/noimage.jpg',
        'timestamp': '3 ชั่วโมงที่แล้ว',
        'isRead': true,
        'action': 'เสนอราคาใหม่',
      },
      {
        'id': '4',
        'type': 'auction_ending',
        'title': 'ประมูลใกล้สิ้นสุด',
        'message': 'ประมูล Sony A7R V Camera จะสิ้นสุดใน 30 นาที',
        'auctionTitle': 'Sony A7R V Camera',
        'auctionId': 'AUCT-2025-004',
        'currentPrice': 120000,
        'image': 'assets/images/noimage.jpg',
        'timestamp': '1 วันที่แล้ว',
        'isRead': true,
        'action': 'ดูรายละเอียด',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ทำเครื่องหมายว่าอ่านแล้วทั้งหมด'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'อ่านแล้วทั้งหมด',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ไม่มีการแจ้งเตือน',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationItem(context, notifications[index]);
              },
            ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, dynamic> notification) {
    final bool isWonAuction = notification['type'] == 'auction_won';
    final bool isUnread = !notification['isRead'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          _handleNotificationTap(context, notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification['type']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getNotificationIcon(notification['type']),
                  color: _getNotificationColor(notification['type']),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                              color: isUnread ? Colors.black : Colors.grey[800],
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Auction info card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              notification['image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['auctionTitle'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isWonAuction
                                      ? 'ราคาที่ชนะ: ฿${NumberFormat('#,###').format(notification['finalPrice'])}'
                                      : 'ราคาปัจจุบัน: ฿${NumberFormat('#,###').format(notification['currentPrice'])}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isWonAuction ? Colors.green : Colors.grey[600],
                                    fontWeight: isWonAuction ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'เลขที่ประมูล: ${notification['auctionId']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification['timestamp'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (isWonAuction)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'ชำระเงิน',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'auction_won':
        return Colors.green;
      case 'auction_outbid':
        return Colors.orange;
      case 'auction_ending':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'auction_won':
        return Icons.emoji_events;
      case 'auction_outbid':
        return Icons.trending_down;
      case 'auction_ending':
        return Icons.timer;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    if (notification['type'] == 'auction_won') {
      // Navigate to payment page or show payment dialog
      _showPaymentDialog(context, notification);
    } else {
      // Navigate to auction detail page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไปยังรายละเอียดการประมูล: ${notification['auctionTitle']}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showPaymentDialog(BuildContext context, Map<String, dynamic> notification) {
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
              _buildInfoRow('สินค้า', notification['auctionTitle']),
              _buildInfoRow('เลขที่ประมูล', notification['auctionId'], isMonospace: true),
              _buildInfoRow('ราคาที่ชนะ', '฿${NumberFormat('#,###').format(notification['finalPrice'])}', isHighlight: true),
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
                    content: Text('ส่งข้อความติดต่อผู้ขายแล้ว (${notification['auctionId']})'),
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
} 