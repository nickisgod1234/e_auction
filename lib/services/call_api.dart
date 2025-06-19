// //ไฟล์นี้เป็นไฟล์ที่ใช้ในการเรียกใช้ api ต่างๆ

// // ignore_for_file: prefer_interpolation_to_compose_strings, camel_case_types

// import 'dart:convert';
// import 'package:another_flushbar/flushbar.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:cm_raot/models/event_cloudmate.dart';
// import 'package:cm_raot/utils/env.dart';
// import 'package:cm_raot/views/config/config_prod.dart';
// import 'package:cm_raot/views/group_cm/home/home_screen.dart';

// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class callApi {
//   //เมธอดเรียกใช้ API: getall ------------------------------------------

//   static Future<String> callAPIUpandDownScore(String _action) async {
//     EasyLoading.show(status: 'loading...');
//     // เรียกใช้ API
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     var myReg = {}; // object
//     myReg['id'] = prefs.getString('id');
//     myReg['new_point'] = 5;
//     myReg['action'] = _action;

//     String jsonReq = jsonEncode(myReg);

//     final response = await http.post(
//       Uri.parse('${Config.apiUrl}/HR-API/personal/update_point_mobile.php'),
//       // Uri.parse(Env.domainURL +
//       //     '/HR-API/event/api_getall_eventcloudmate.php?personal_id=${id}'),
//       body: jsonReq, // ลบการเรียก jsonEncode ที่ไม่จำเป็น
//       headers: {'Content-Type': 'application/json'},
//     );

//     if (response.statusCode == 200) {
//       // เอาข้อมูลที่ส่งกลับมาเป็น JSON แปลงเป็นข้อมูลที่จะนำมาใช้ในแอป และเก็บในตัวแปร
//       final responseData = jsonDecode(response.body);

//       EasyLoading.dismiss();
//       // ส่งค่าข้อมูลที่ส่งกลับมาไปที่จุดเรียกใช้เมธอด
//       return responseData['status'];
//     } else {
//       throw Exception('Failed to fetch data');
//     }
//   }

//   static Future<List<EventCloudmate>> callAPIGetAllEventCloudmate() async {
//     // แสดงหน้าจอแสดงสถานะการโหลด
//     EasyLoading.show(status: 'loading...');

//     // เรียกใช้ SharedPreferences เพื่อดึงข้อมูลที่เก็บไว้
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     // ดึงข้อมูล 'id' จาก SharedPreferences
//     var id = prefs.getString('id');

//     // เรียกใช้ API โดยใช้ http.get และส่งค่า personal_id
//     final response = await http.get(
//       // Uri.parse(Env.domainURLCheckjob + '/getall?personal_id=${id}'), // คอมเมนต์บรรทัดนี้ไว้
//       Uri.parse(Env.domainURL +
//           '/HR-API/event/api_getall_eventcloudmate.php?personal_id=${id}'),
//       headers: {'Content-Type': 'application/json'},
//     );

//     // ตรวจสอบว่าการเรียก API สำเร็จ (status code 200)
//     if (response.statusCode == 200) {
//       // แปลงข้อมูล JSON ที่ส่งกลับมาเป็นข้อมูลที่จะใช้ในแอปฯ
//       final responseData = jsonDecode(response.body);

//       // แปลงข้อมูล JSON ให้เป็น List ของ EventCloudmate
//       final eventcloudmateDataList =
//           await responseData.map<EventCloudmate>((json) {
//         return EventCloudmate.fromJson(json);
//       }).toList();

//       // ยกเลิกการแสดงหน้าจอแสดงสถานะการโหลด
//       EasyLoading.dismiss();

//       // ส่งค่าข้อมูลที่แปลงแล้วกลับไป ณ จุดที่เรียกใช้เมธอดนี้ เพื่อนำข้อมูลไปใช้งาน
//       return eventcloudmateDataList;
//     } else {
//       // ถ้าการเรียก API ไม่สำเร็จ ให้ส่งข้อผิดพลาด
//       throw Exception('Failed to fetch data');
//     }
//   }

//   static Future<List<EventCloudmate>> callAPIGetAllEventCloudmateUser() async {
//     try {
//       EasyLoading.show(status: 'loading...');
//       //เรียกใช้ API
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       var id = prefs.getString('id');
      
//       final response = await http.get(
//         Uri.parse('${Config.apiUrlotpsever}event/api_getall_eventcloudmate_user.php?personal_id=${id}'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 200) {
//         //เอาข้อมูลที่ส่งกลับมาเป็น JSON แปลงเป็นข้อมูลที่จะนำมาใช้ในแอปฯ เก็บในตัวแปร
//         final responseData = jsonDecode(response.body);
        
//         if (responseData is List) {
//           //แปลงข้อมูลให้เป็น List และเก็บในตัวแปร List
//           final eventcloudmateDataList = responseData.map<EventCloudmate>((json) {
//             return EventCloudmate.fromJson(json);
//           }).toList();
          
//           EasyLoading.dismiss();
//           return eventcloudmateDataList;
//         } else {
//           EasyLoading.dismiss();
//           throw Exception('Invalid response format');
//         }
//       } else {
//         EasyLoading.dismiss();
//         throw Exception('Failed to fetch data: ${response.statusCode}');
//       }
//     } catch (e) {
//       EasyLoading.dismiss();
//       print('Error in callAPIGetAllEventCloudmateUser: $e');
//       throw Exception('Failed to fetch data: $e');
//     }
//   }

//   static Future<List<EventCloudmate>> callAPIGetDetailEventCloudmate(id) async {
//     EasyLoading.show(status: 'loading...');
//     //เรียกใช้ API
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     var personal_id = await prefs.getString('id');

//     final response = await http.get(
//       Uri.parse(Env.domainURL+
//           //     '/getdetail?personal_id=${personal_id}&id=${id}'),
//           '/HR-API/event/api_get_detail_eventcloudmate.php?personal_id=${personal_id}&id=${id}'),
//       headers: {'Content-Type': 'application/json'},
//     );
//     EasyLoading.dismiss();
//     if (response.statusCode == 200) {
//       //เอาข้อมูลที่ส่งกลับมาเป็น JSON แปลงเป็นข้อมูลที่จะนำมาใช้ในแอปฯ เก็บในตัวแปร
//       final responseData = jsonDecode(response.body);

//       //แปลงข้อมูลให้เป็น List และเก็บในตัวแปร List
//       final eventcloudmateDataList =
//           await responseData.map<EventCloudmate>((json) {
//         return EventCloudmate.fromJson(json);
//       }).toList();

//       //ส่งค่าข้อมูลที่เก็บในตัวแปร List กลับไป ณ จุดที่เรียกใช้เมธอดนี้ เพื่อนำข้อมูลไปใช้งาน
//       return eventcloudmateDataList;
//     } else {
//       throw Exception('Failed to fetch data');
//     }
//   }

//   // static Future<List<EventCloudmate>> callAPIGetDetailEventCloudmate(id) async {
//   //   EasyLoading.show(status: 'loading...');
//   //   //เรียกใช้ API
//   //   SharedPreferences prefs = await SharedPreferences.getInstance();

//   //   var personal_id = prefs.getString('personal_id');
//   //   final response = await http.get(
//   //     Uri.parse(Env.domainURL +
//   //         '/hrcloudmate_api/getdetail?id=${id}&personal_id=${personal_id}'),
//   //     headers: {'Content-Type': 'application/json'},
//   //   );

//   //   if (response.statusCode == 200) {
//   //     //เอาข้อมูลที่ส่งกลับมาเป็น JSON แปลงเป็นข้อมูลที่จะนำมาใช้ในแอปฯ เก็บในตัวแปร
//   //     final responseData = jsonDecode(response.body);
//   //     print(responseData[0]['message']);
//   //     EasyLoading.dismiss();
//   //     if (responseData[0]['message'] == '1') {
//   //       final eventcloudmateDataList =
//   //           await responseData.map<EventCloudmate>((json) {
//   //         return EventCloudmate.fromJson(json);
//   //       }).toList();

//   //       return eventcloudmateDataList;
//   //     } else {
//   //       return [];
//   //     }

//   //     //แปลงข้อมูลให้เป็น List และเก็บในตัวแปร List

//   //     //ส่งค่าข้อมูลที่เก็บในตัวแปร List กลับไป ณ จุดที่เรียกใช้เมธอดนี้ เพื่อนำข้อมูลไปใช้งาน
//   //   } else {
//   //     throw Exception('Failed to fetch data');
//   //   }
//   // }

//   //เมธอดเรียกใช้ API: insert ------------------------------------------
//   static Future<String> calAPIInsertEventCloudmated(
//       EventCloudmate eventcloudmate) async {
//     EasyLoading.show(status: 'loading...');
//     //เรียกใช้ API

//     final response = await http.post(
//       // Uri.parse(Env.domainURLCheckjob + '/insert'),
//       Uri.parse(Env.domainURL + '/HR-API/event/api_insert_eventcloudmate.php'),
//       body: jsonEncode(eventcloudmate.toJson()),
//       headers: {'Content-Type': 'application/json'},
//     );
//     // final responseData = jsonDecode(response.body);
//     print('=======================');
//     print(response.body);

//     if (response.statusCode == 200) {
//       //เอาข้อมูลที่ส่งกลับมาเป็น JSON แปลงเป็นข้อมูลที่จะนำมาใช้ในแอปฯ เก็บในตัวแปร
//       final responseData = jsonDecode(response.body);
//       EasyLoading.dismiss();
//       //ส่งค่าข้อมูลที่ส่งกลับมาไปที่จุดเรียกใช้เมธอด
//       return responseData['message'];
//     } else {
//       throw Exception('Failed to fetch data');
//     }
//   }

//   static Future<String> calAPIInsertEventLogCloudmated(
//       EventCloudmate eventcloudmate) async {
//     EasyLoading.show(status: 'loading...');
//     //เรียกใช้ API

//     final response = await http.post(
//       Uri.parse(
//           Env.domainURL + '/HR-API/event/api_insert_log_eventcloudmate.php'),
//       // Env.domainURLCheckjob + '/hrcloudamte_api/add_pic_event.php'),
//       body: jsonEncode(eventcloudmate.toJson()),
//       headers: {'Content-Type': 'application/json'},
//     );

//     if (response.statusCode == 200) {
//       //เอาข้อมูลที่ส่งกลับมาเป็น JSON แปลงเป็นข้อมูลที่จะนำมาใช้ในแอปฯ เก็บในตัวแปร
//       final responseData = jsonDecode(response.body);
//       // print(responseData);
//       EasyLoading.dismiss();
//       //ส่งค่าข้อมูลที่ส่งกลับมาไปที่จุดเรียกใช้เมธอด
//       return responseData['message'];
//     } else {
//       throw Exception('Failed to fetch data');
//     }
//   }

//   static Future<String> calAPIUpdateEventLogCloudmated(
//       EventCloudmate eventcloudmate) async {
//     EasyLoading.show(status: 'loading...');
//     //เรียกใช้ API

//     final response = await http.post(
//       Uri.parse(
//           Env.domainURL + '/HR-API/event/api_insert_log_eventcloudmate.php'),
//       body: jsonEncode(eventcloudmate.toJson()),
//       headers: {'Content-Type': 'application/json'},
//     );

//     if (response.statusCode == 200) {
//       //เอาข้อมูลที่ส่งกลับมาเป็น JSON แปลงเป็นข้อมูลที่จะนำมาใช้ในแอปฯ เก็บในตัวแปร
//       final responseData = jsonDecode(response.body);
//       EasyLoading.dismiss();
//       //ส่งค่าข้อมูลที่ส่งกลับมาไปที่จุดเรียกใช้เมธอด
//       return responseData['message'];
//     } else {
//       throw Exception('Failed to fetch data');
//     }
//   }

//   // static Future<String> calAPIUpdateLineUIDCloudmated(
//   //     EventCloudmate eventcloudmate) async {
//   //   EasyLoading.show(status: 'loading...');
//   //   //เรียกใช้ API

//   //   final response = await http.get(
//   //     Uri.parse(Env.line_uid + '310'),
//   //     // body: jsonEncode(eventcloudmate.toJson()),
//   //     headers: {'Content-Type': 'application/json'},
//   //   );
//   //   print(response.body);

//   //   if (response.statusCode == 200) {
//   //     //เอาข้อมูลที่ส่งกลับมาเป็น JSON แปลงเป็นข้อมูลที่จะนำมาใช้ในแอปฯ เก็บในตัวแปร
//   //     final responseData = jsonDecode(response.body);

//   //     EasyLoading.dismiss();
//   //     //ส่งค่าข้อมูลที่ส่งกลับมาไปที่จุดเรียกใช้เมธอด
//   //     return responseData['message'];
//   //   } else {
//   //     throw Exception('Failed to fetch data');
//   //   }
//   // }

//   //เมธอดเรียกใช้ API: update ------------------------------------------
//   static Future<String> calAPIUpdateEventCloudmate(
//       EventCloudmate eventcloudmate) async {
//     EasyLoading.show(status: 'loading...');
//     final response = await http.post(
//       Uri.parse(Env.domainURL + '/hrcloudmate_api/update'),
//       body: jsonEncode(eventcloudmate.toJson()),
//       headers: {'Content-Type': 'application/json'},
//     );

//     if (response.statusCode == 200) {
//       final responseData = jsonDecode(response.body);
//       EasyLoading.dismiss();
//       return responseData['message'];
//     } else {
//       throw Exception('Failed to fetch data');
//     }
//   }

//   static Future<String> calAPIsendJobEventCloudmate(
//       EventCloudmate eventcloudmate) async {
//     EasyLoading.show(status: 'loading...');
//     final response = await http.post(
//       Uri.parse(
//           Env.domainURL + '/HR-API/event/api_send_job_eventcloudmate.php'),
//       // Env.domainURLCheckjob + '/sendjob'),
//       body: jsonEncode(eventcloudmate.toJson()),
//       headers: {'Content-Type': 'application/json'},
//     );

//     if (response.statusCode == 200) {
//       final responseData = jsonDecode(response.body);
//       EasyLoading.dismiss();
//       return responseData['message'];
//     } else {
//       throw Exception('Failed to fetch data');
//     }
//   }

//   //เมธอดเรียกใช้ API: delete ------------------------------------------
//   static Future<String> calAPIDeleteEventCloudmate(
//       EventCloudmate eventcloudmate) async {
//     EasyLoading.show(status: 'loading...');
//     //เรียกใช้ API
//     final response = await http.post(
//       Uri.parse(Env.domainURL + '/hrcloudmate_api/delete'),
//       body: jsonEncode(eventcloudmate.toJson()),
//       headers: {'Content-Type': 'application/json'},
//     );

//     if (response.statusCode == 200) {
//       //เอาข้อมูลที่ส่งกลับมาเป็น JSON แปลงเป็นข้อมูลที่จะนำมาใช้ในแอปฯ เก็บในตัวแปร
//       final responseData = jsonDecode(response.body);

//       //ส่งค่าข้อมูลที่ส่งกลับมาไปที่จุดเรียกใช้เมธอด
//       EasyLoading.dismiss();
//       return responseData['message'];
//     } else {
//       throw Exception('Failed to fetch data');
//     }
//   }
// }

// var company_name = '';

// Future<void> getCompanyName(String id, Function(String) callback) async {
//   EasyLoading.show(status: 'loading...');

//   final response = await http
//       // .get(Uri.parse('${Config.apiUrl}/hrcloudmate_api/company_name.php'));
//       .get(Uri.parse(
//           '${Config.apiUrl}/HR-API/company_profile/company_name.php?id=${id}'));

//   try {
//     if (response.statusCode == 200) {
//       var data_res = await json.decode(response.body);

//       if (data_res['status'] == 'success') {
//         var companyName = data_res['data_res']['company_name'];
//         callback(
//             companyName); // เรียกใช้ callback เพื่อส่งค่า company_name กลับไปยัง caller
//       } else {
//         // handle error case
//       }
//     } else {
//       // handle error case
//     }
//   } catch (e) {
//     // handle error case
//   }
//   EasyLoading.dismiss();
// }
// // var company_name = '';

// getstatuspage() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();

//   var id = await prefs.getString('id');
//   final response = await http
//       // .get(Uri.parse('${Config.apiUrlcheckjob}/get_profile_page.php?id=${id}'));
//       .get(Uri.parse(
//           '${Config.apiUrl}/HR-API/personal/get_profile_page.php?id=${id}'));

//   try {
//     if (response.statusCode == 200) {
//       var data_res = await json.decode(response.body);

//       if (data_res['status'] == 'success') {
//         return data_res;
//       } else {
//         print('status != success');
//         // return data_res['status'];
//       }
//     } else {
//       print('response code != 200');
//     }
//   } catch (e) {
//     print(e);
//   }

//   EasyLoading.dismiss();
// }

// Future<Map<String, dynamic>> get_profile() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   EasyLoading.show(status: 'loading...');
//   var id = await prefs.getString('id');
//   final response = await http.get(
//       Uri.parse('${Config.apiUrl}/HR-API/personal/get_profile.php?id=${id}'));

//   try {
//     if (response.statusCode == 200) {
//       var dataRes = await json.decode(response.body);
//       // print(dataRes);

//       return dataRes;
//     } else {
//       throw Exception(
//           'Failed to load profile data. Error code: ${response.statusCode}');
//     }
//   } catch (e) {
//     print(e);
//     throw Exception('Failed to parse profile data.');
//   } finally {
//     EasyLoading.dismiss();
//   }
// }

// Future event_count() async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   EasyLoading.show(status: 'loading...');
//   var id = await prefs.getString('id');
//   final response = await http.get(Uri.parse(
//       // '${Config.apiUrlcheckjob}/event_count.php?id=${id}&type=count'));
//       '${Config.apiUrl}/HR-API/event/event_count.php?id=${id}&type=count'));

//   try {
//     if (response.statusCode == 200) {
//       var dataRes = json.decode(response.body);
//       // print(dataRes);
//       if (dataRes['status'] == 'success') {
//         return dataRes['count_row'];
//       }
//       return dataRes;
//     } else {
//       throw Exception(
//           'Failed to load profile data. Error code: ${response.statusCode}');
//     }
//   } catch (e) {
//     print(e);
//     // throw Exception('Failed to parse profile data.');
//   } finally {
//     EasyLoading.dismiss();
//   }
// }

// Future event_read_update(String? event_id) async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();

//   var id = await prefs.getString('id');

//   await http.get(Uri.parse(
//       '${Config.apiUrl}/HR-API/event/event_count.php?id=${id}&type=update&event_id=${event_id}'));
//   // var data_res = await json.decode(test.body);
// }
