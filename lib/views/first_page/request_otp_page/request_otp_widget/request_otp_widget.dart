import 'package:flutter/material.dart';

class RequestOtpWidget extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController pinController;
  final bool isPinVisible;
  final String refno;
  final bool isRequestEnabled;
  final int countdown;
  final bool isLoading;
  final VoidCallback onSubmitPhone;
  final VoidCallback onVerifyOtp;
  final VoidCallback onRequestNewOtp;

  RequestOtpWidget({
    required this.phoneController,
    required this.pinController,
    required this.isPinVisible,
    required this.refno,
    required this.isRequestEnabled,
    required this.countdown,
    required this.isLoading,
    required this.onSubmitPhone,
    required this.onVerifyOtp,
    required this.onRequestNewOtp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isPinVisible) ...[
          TextField(
            controller: phoneController,
            decoration: InputDecoration(labelText: 'กรอกเบอร์โทรศัพท์'),
            keyboardType: TextInputType.phone,
          ),
          ElevatedButton(
            onPressed: onSubmitPhone,
            child: Text("ตกลง"),
          ),
        ] else ...[
          Text(
            'REFNO: $refno',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: pinController,
            decoration: InputDecoration(labelText: 'กรอกรหัส PIN'),
            keyboardType: TextInputType.number,
          ),
          ElevatedButton(
            onPressed: onVerifyOtp,
            child: Text("ยืนยัน"),
          ),
          ElevatedButton(
            onPressed: isRequestEnabled ? onRequestNewOtp : null,
            child: Text(
              isRequestEnabled ? 'ขอรหัสใหม่' : 'รอ $countdown วินาที',
            ),
          ),
        ],
        if (isLoading) CircularProgressIndicator(),
      ],
    );
  }
}
