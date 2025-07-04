// import 'package:e_auction/views/first_page/auction_page/auction_result_page.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:e_auction/utils/format.dart';

// class AllWinnerAnnouncementsPage extends StatelessWidget {
//   final List<Map<String, dynamic>> winnerAnnouncements;

//   const AllWinnerAnnouncementsPage(
//       {super.key, required this.winnerAnnouncements});

//   Widget _buildWinnerListItem(
//       BuildContext context, Map<String, dynamic> auction) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       clipBehavior: Clip.antiAlias,
//       child: InkWell(
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AuctionResultPage(auctionData: auction),
//             ),
//           );
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Row(
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.asset(
//                   auction['image'],
//                   width: 80,
//                   height: 80,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     return Container(
//                       width: 80,
//                       height: 80,
//                       color: Colors.grey[200],
//                       child:
//                           Icon(Icons.image_not_supported, color: Colors.grey),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       auction['title'],
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'ราคาปิด: ${Format.formatCurrency(auction['finalPrice'])}',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'ผู้ชนะ: ${auction['winner']}',
//                       style: const TextStyle(
//                         fontSize: 14,
//                         color: Colors.green,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'จบเมื่อ: ${auction['completedDate']}',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('ประกาศผลผู้ชนะทั้งหมด'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 1,
//       ),
//       body: winnerAnnouncements.isEmpty
//           ? const Center(
//               child: Text(
//                 'ไม่มีการประกาศผลผู้ชนะ',
//                 style: TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//             )
//           : ListView.builder(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               itemCount: winnerAnnouncements.length,
//               itemBuilder: (context, index) {
//                 return _buildWinnerListItem(
//                     context, winnerAnnouncements[index]);
//               },
//             ),
//     );
//   }
// } 