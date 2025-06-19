import 'package:flutter/material.dart';
import 'package:e_auction/utils/tool_utility.dart';

class ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  ProfileTextField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(0),
        child: TextField(
          enabled: false,
          controller: controller,
          decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontFamily: ToolUtility.fontPromptRegular,
                fontSize: ToolUtility.autoSize(context, 20),
                color:
                    ToolUtility.colorBlueCustom8, // เปลี่ยนสีตามที่คุณต้องการ
              ),
              disabledBorder:
                  UnderlineInputBorder(borderSide: BorderSide.none)),
          style: TextStyle(
            fontFamily: ToolUtility.fontPromptRegular,
            fontSize: ToolUtility.autoSize(context, 15),
            color: ToolUtility.colorBlack, // เปลี่ยนสีตามที่คุณต้องการ
          ),
        ),
      ),
    );
  }
}

class EditProfileTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  EditProfileTextField({required this.label, required this.controller});

  @override
  State<EditProfileTextField> createState() => _EditProfileTextFieldState();
}

class _EditProfileTextFieldState extends State<EditProfileTextField> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        // enabled: false,
        controller: widget.controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide(width: 0)),
          disabledBorder: InputBorder.none,
          labelText: widget.label,
          labelStyle: TextStyle(
            fontFamily: ToolUtility.fontPromptRegular,
            fontSize: ToolUtility.autoSize(context, 15),
            color: ToolUtility.colorBlack, // เปลี่ยนสีตามที่คุณต้องการ
          ),
        ),
        style: TextStyle(
          fontFamily: ToolUtility.fontPromptRegular,
          fontSize: ToolUtility.autoSize(context, 15),
          color: ToolUtility.colorBlack, // เปลี่ยนสีตามที่คุณต้องการ
        ),
      ),
    );
  }
}
