// ignore_for_file: avoid_single_cascade_in_expression_statements

import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_auction/utils/tool_utility.dart';

void showAlertBar(
    BuildContext context, String title, String message, IconData iconData,
    {required Color color}) {
  Flushbar(
    title: title,
    message: message,
    icon: Icon(
      iconData,
      size: 28.0,
      color: color ??
          Colors.blue[300], // ใช้ค่า Colors.blue[300] ถ้า color เป็น null
    ),
    duration: Duration(seconds: 3),
    margin: EdgeInsets.all(8),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  )..show(context);
}

void showAlertDialog(
    BuildContext context, String titleText, String contentText) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Align(
          alignment: Alignment.center,
          child: Text(
            titleText,
            style: TextStyle(
              fontFamily: ToolUtility.fontPromptRegular,
              fontSize: ToolUtility.autoSize(context, 15),
              color: ToolUtility.colorBlack,
            ),
          ),
        ),
        content: Text(
          contentText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: ToolUtility.fontPromptRegular,
            fontSize: ToolUtility.autoSize(context, 15),
            color: ToolUtility.colorBlack,
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'ตกลง',
                  style: TextStyle(
                    fontFamily: ToolUtility.fontPromptRegular,
                    fontSize: ToolUtility.autoSize(context, 15),
                    color: ToolUtility.colorWhite,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ToolUtility.colorCompany,
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
// void showWarningDialog(context, msg) {
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: Align(
//         alignment: Alignment.center,
//         child: Text(
//           'คำเตือน',
//           style: GoogleFonts.kanit(),
//         ),
//       ),
//       content: Text(
//         msg,
//         style: GoogleFonts.kanit(),
//       ),
//       actions: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 _ontapback(context);
//               },
//               child: Text(
//                 'ตกลง',
//                 style: GoogleFonts.kanit(),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//               ),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

typedef VoidCallback = void Function();

void confirm_showWarningDialog(
    BuildContext context, String msg, VoidCallback onPressed) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Align(
        alignment: Alignment.center,
        child: Text(
          'คำเตือน',
          style: GoogleFonts.kanit(),
        ),
      ),
      content: Text(
        msg,
        style: GoogleFonts.kanit(),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onPressed,
              child: Text(
                'ตกลง',
                style: GoogleFonts.kanit(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
