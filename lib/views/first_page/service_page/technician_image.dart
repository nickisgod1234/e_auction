import 'dart:io';

import 'package:flutter/material.dart';

/// รูปช่างอาจเป็นไฟล์ในเครื่องตอนเลือกใหม่ หรือที่อยู่จาก ERP หลังบันทึกแล้ว
Widget technicianImage(
  String source, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  final broken = Container(
    width: width,
    height: height,
    color: Colors.grey[200],
    child: const Icon(Icons.broken_image_outlined),
  );
  if (source.startsWith('http')) {
    return Image.network(
      source,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => broken,
    );
  }
  return Image.file(
    File(source),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => broken,
  );
}
