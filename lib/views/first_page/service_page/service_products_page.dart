import 'package:flutter/material.dart';

/// จุดเริ่มของงานช่าง ยังไม่มีรายการบริการ
class ServiceProductsPage extends StatelessWidget {
  const ServiceProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สินค้าบริการ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.handyman_outlined, size: 56, color: Color(0xFF8A8A8A)),
              SizedBox(height: 16),
              Text(
                'สินค้าบริการสำหรับงานช่าง',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'รายการบริการจะมาแสดงที่หน้านี้',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
