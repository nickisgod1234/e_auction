// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:e_auction/utils/tool_utility.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:e_auction/views/config/config_prod.dart';
// void get_status_page(BuildContext context, String current_page) async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();

//   // ตรวจสอบว่ามี token อยู่หรือไม่
//   String? token = await prefs.getString('token');

//   // ถ้ามี token จะทำการเรียก API
//   if (token != null) {
//     var id = await prefs.getString('id');
//     final response = await http.get(
//       Uri.parse(Config.apiUrl + '/HR-API/personal/get_profile_page.php?id=$id'),
//       headers: {'Content-Type': 'application/json'},
//     );

//     // ตรวจสอบสถานะของการตอบกลับ
//     if (response.statusCode == 200) {
//       // แปลงข้อมูล JSON ที่ตอบกลับ
//       final responseData = jsonDecode(response.body);

//       // ตรวจสอบว่าข้อมูลเป็น Map และมี key 'data_res'
//       if (responseData is Map && responseData.containsKey('data_res')) {
//         var dataRes = responseData['data_res'];

//         // ตรวจสอบว่า data_res เป็น Map หรือไม่
//         if (dataRes is Map) {
//           var group_cm = dataRes['group_cm'];
//           var group_sp = dataRes['group_sp'];
//           var group_admin = dataRes['group_admin'];
//           var pdpa = dataRes['pdpa'];

//           // ตรวจสอบว่า pdpa ไม่เท่ากับ '1'
//           if (pdpa != '1') {
//             await prefs.remove('token');
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => LoginScreen()),
//             );
//             return; // ออกจากฟังก์ชันหลังจากการนำทาง
//           }

//           var number = 0;

//           if (group_cm == '1') number++;
//           if (group_sp == '1') number++;
//           if (group_admin == '1') number++;

//           // ตรวจสอบกลุ่มและนำทางไปยังหน้าที่เหมาะสม
//           if (group_cm == '1' &&
//               group_sp == '0' &&
//               group_admin == '0' &&
//               number == 1 &&
//               current_page != 'HomeScreen') {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => HomeScreen()),
//             );
//           } else if (group_admin == '1' &&
//               group_cm == '0' &&
//               group_sp == '0' &&
//               number == 1 &&
//               current_page != 'AdminDashBoardScreen') {
//             // เพิ่มการนำทางไปยัง AdminHomeScreen ที่นี่ถ้าต้องการ
//           } else if (number > 1 && current_page != 'ChoosePage') {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => ChoosePage()),
//             );
//           }
//         } else {
//           print('data_res is not a Map: $dataRes');
//         }
//       } else {
//         print('responseData is not a Map or missing data_res: $responseData');
//       }
//     } else {
//       print('Error: ${response.statusCode} ${response.body}');
//     }
//   }
// }
