import 'package:flutter/material.dart';
import 'package:e_auction/utils/format.dart';

class AuctionPendingBidDialog extends StatelessWidget {
  final Map<String, dynamic> pendingBid;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const AuctionPendingBidDialog({
    Key? key,
    required this.pendingBid,
    required this.onCancel,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (pendingBid['isReverseAuction'] == true) 
                ? Colors.red.withOpacity(0.1) 
                : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              (pendingBid['isReverseAuction'] == true) ? Icons.trending_down : Icons.timer, 
              color: (pendingBid['isReverseAuction'] == true) ? Colors.red : Colors.orange, 
              size: 24
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              (pendingBid['isReverseAuction'] == true) ? 'ยืนยันการเสนอราคา' : 'ยืนยันการประมูล',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: (pendingBid['isReverseAuction'] == true) ? Colors.red[700] : Colors.orange[700],
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (pendingBid['isReverseAuction'] == true) 
              ? 'คุณต้องการยืนยันการเสนอราคาหรือไม่?'
              : 'คุณต้องการยืนยันการประมูลหรือไม่?',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200] ?? Colors.grey),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('สินค้า:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    Expanded(
                      child: Text(
                        pendingBid['productTitle'] ?? 'ไม่ระบุ',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ราคาปัจจุบัน:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    Text(
                      Format.formatCurrency(pendingBid['currentPrice'] ?? 0),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (pendingBid['isReverseAuction'] == true) ? 'ราคาที่เสนอ:' : 'ราคาที่ประมูล:', 
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])
                    ),
                    Text(
                      Format.formatCurrency(int.parse(pendingBid['bidAmount'])),
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: (pendingBid['isReverseAuction'] == true) ? Colors.red : Colors.green
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'กรุณาตรวจสอบราคาก่อนยืนยัน',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'ยกเลิก',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onConfirm,
          child: Text('ยืนยันการประมูล'),
        ),
      ],
    );
  }
} 