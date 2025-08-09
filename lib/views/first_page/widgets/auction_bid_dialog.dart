import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:e_auction/utils/format.dart';
import 'package:e_auction/views/first_page/widgets/auction_image_widget.dart';

class AuctionBidDialog extends StatefulWidget {
  final Map<String, dynamic> auctionData;
  final Map<String, dynamic> latestData;
  final Function(Map<String, dynamic>) onBidConfirmed;
  final Function() onCancel;

  const AuctionBidDialog({
    Key? key,
    required this.auctionData,
    required this.latestData,
    required this.onBidConfirmed,
    required this.onCancel,
  }) : super(key: key);

  @override
  _AuctionBidDialogState createState() => _AuctionBidDialogState();
}

class _AuctionBidDialogState extends State<AuctionBidDialog> {
  final TextEditingController bidController = TextEditingController();
  late int currentPrice;
  late int minimumIncrease;
  late int minBid;
  late bool isReverseAuction;

  @override
  void initState() {
    super.initState();
    _initializeBidData();
  }

  void _initializeBidData() {
    currentPrice = int.tryParse(widget.latestData['current_price']?.toString() ?? '0') ?? 0;
    minimumIncrease = int.tryParse(widget.latestData['minimum_increase']?.toString() ?? '0') ?? 0;
    
    // ตรวจสอบประเภทการประมูล
    final quotationTypeCode = widget.auctionData['quotation_type_code']?.toString() ?? '';
    isReverseAuction = quotationTypeCode == "AS02";
    
    // คำนวณราคาขั้นต่ำตามประเภทการประมูล
    if (isReverseAuction) {
      // Reverse Auction: ราคาลดลง
      minBid = currentPrice - minimumIncrease;
    } else {
      // Normal Auction: ราคาขึ้น
      minBid = currentPrice + minimumIncrease;
    }
    
    // คำนวณขีดจำกัด 20% ของราคาขั้นต่ำ
    final maxBidLimit = (minBid * 1.2).round();
    final minBidLimit = (currentPrice * 0.8).round();
    print('DEBUG: Current Price: $currentPrice');
    print('DEBUG: Min Bid: $minBid');
    print('DEBUG: Minimum Increase: $minimumIncrease');
    print('DEBUG: Max Bid Limit (Min Bid * 1.2): $maxBidLimit');
    print('DEBUG: Min Bid Limit (20%): $minBidLimit');
    print('DEBUG: Calculation: $minBid * 1.2 = ${minBid * 1.2}');
    
    bidController.text = Format.formatNumber(minBid);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 1,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    // Container(
                    //   padding: EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: isReverseAuction 
                    //       ? Colors.red.withOpacity(0.1) 
                    //       : Colors.green.withOpacity(0.1),
                    //     shape: BoxShape.circle,
                    //   ),
                    //   child: Icon(
                    //     isReverseAuction ? Icons.trending_down : Icons.gavel, 
                    //     color: isReverseAuction ? Colors.red : Colors.green, 
                    //     size: 48
                    //   ),
                    // ),
                    SizedBox(height: 16),
                    Text(
                      isReverseAuction ? 'เสนอราคา (Reverse Auction)' : 'ลงประมูลสินค้า',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isReverseAuction ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AuctionImageWidget(
                              imagePath: widget.auctionData['image'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.auctionData['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'ผู้ขาย: Cloudmate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isReverseAuction 
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                            isReverseAuction 
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isReverseAuction 
                          ? Colors.red.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ราคาปัจจุบัน:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                Format.formatCurrency(currentPrice),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isReverseAuction ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isReverseAuction ? 'ราคาสูงสุดที่เสนอได้:' : 'ราคาขั้นต่ำ:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                Format.formatCurrency(minBid),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isReverseAuction ? Colors.red : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: bidController,
                          decoration: InputDecoration(
                            labelText: isReverseAuction 
                              ? 'ราคาที่ต้องการเสนอ (บาท)' 
                              : 'ราคาที่ต้องการประมูล (บาท)',
                            hintText: Format.formatNumber(minBid),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isReverseAuction ? Colors.red : Colors.green, 
                                width: 2
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.attach_money, 
                              color: isReverseAuction ? Colors.red : Colors.green
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 16),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            // แปลงตัวเลขเป็นรูปแบบที่มี comma
                            if (value.isNotEmpty) {
                              final number = int.tryParse(value.replaceAll(',', ''));
                              if (number != null) {
                                final formattedValue = Format.formatNumber(number);
                                if (formattedValue != value) {
                                  bidController.value = TextEditingValue(
                                    text: formattedValue,
                                    selection: TextSelection.collapsed(
                                      offset: formattedValue.length,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        SizedBox(height: 8),
                                                  Builder(
                            builder: (context) {
                              final maxBidDisplay = (minBid * 1.2).round();
                              final minBidDisplay = (currentPrice * 0.8).round();
                              print('DEBUG: Display - Current Price: $currentPrice');
                              print('DEBUG: Display - Min Bid: $minBid');
                              print('DEBUG: Display - Max Bid: $maxBidDisplay');
                              print('DEBUG: Display - Calculation: $minBid * 1.2 = $maxBidDisplay');
                            
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isReverseAuction 
                                    ? 'สูงสุด: ${Format.formatCurrency(minBid)}'
                                    : 'ขั้นต่ำ: ${Format.formatCurrency(minBid)}',
                                  style: TextStyle(
                                    color: isReverseAuction ? Colors.red[700] : Colors.orange[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  isReverseAuction 
                                    ? 'ขั้นต่ำ: ${Format.formatCurrency(minBidDisplay)}'
                                    : 'สูงสุด: ${Format.formatCurrency(maxBidDisplay)}',
                                  style: TextStyle(
                                    color: isReverseAuction ? Colors.red[700] : Colors.orange[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: widget.onCancel,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, size: 20),
                            SizedBox(width: 8),
                            Text('ยกเลิก',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReverseAuction ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                        ),
                        onPressed: () {
                          final bidAmount = int.tryParse(bidController.text.replaceAll(',', ''));
                          if (bidAmount == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('กรุณากรอกราคาที่ถูกต้อง'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          if (isReverseAuction) {
                            // Reverse Auction: ราคาต้องน้อยกว่าหรือเท่ากับ minBid (สูงสุดที่เสนอได้)
                            if (bidAmount > minBid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('ราคาต้องน้อยกว่าหรือเท่ากับ ${Format.formatCurrency(minBid)}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          } else {
                            // Normal Auction: ราคาต้องมากกว่าหรือเท่ากับ minBid
                            if (bidAmount < minBid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('ราคาต้องมากกว่าหรือเท่ากับ ${Format.formatCurrency(minBid)}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }
                          
                          // ตรวจสอบขีดจำกัด 20% ของราคาขั้นต่ำ
                          final maxBid = (minBid * 1.2).round();
                          final minBidLimit = (currentPrice * 0.8).round();
                          
                          if (isReverseAuction) {
                            // Reverse Auction: ตรวจสอบขีดจำกัด
                            if (bidAmount < minBidLimit) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('ราคาไม่สามารถต่ำกว่า ${Format.formatCurrency(minBidLimit)} ได้'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          } else {
                            // Normal Auction: ตรวจสอบขีดจำกัด
                            if (bidAmount > maxBid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('ราคาไม่สามารถเกิน ${Format.formatCurrency(maxBid)} ได้'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }

                          // ส่งข้อมูลการประมูลกลับไป
                          widget.onBidConfirmed({
                            'bidAmount': bidAmount,
                            'minimumIncrease': minimumIncrease,
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isReverseAuction ? Icons.trending_down : Icons.gavel, size: 20),
                            SizedBox(width: 8),
                            Text(isReverseAuction ? 'เสนอราคา' : 'ยืนยัน',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
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
  }
} 