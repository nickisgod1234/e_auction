import 'package:intl/intl.dart';

class TimeCalculator {
  /// คำนวณเวลาที่เหลือของการประมูล
  static String calculateTimeRemaining({
    required DateTime? startDate,
    required DateTime? endDate,
    required String status,
  }) {
    final now = DateTime.now();
    
    // ถ้าไม่มีวันที่เริ่มหรือสิ้นสุด
    if (startDate == null || endDate == null) {
      return 'ไม่ระบุเวลา';
    }
    
    switch (status) {
      case 'current':
        // กำลังประมูล - คำนวณเวลาที่เหลือจนสิ้นสุด
        final remainingTime = _calculateRemainingTime(now, endDate);
        return remainingTime == 'หมดเวลา' ? 'สิ้นสุดแล้ว' : 'เหลือ $remainingTime';
        
      case 'upcoming':
        // ยังไม่เริ่ม - คำนวณเวลาที่เหลือจนเริ่ม
        final remainingTime = _calculateRemainingTime(now, startDate);
        return remainingTime == 'หมดเวลา' ? 'เริ่มแล้ว' : 'เริ่มในอีก $remainingTime';
        
      case 'completed':
        // สิ้นสุดแล้ว
        return 'สิ้นสุดแล้ว';
        
      default:
        // ตรวจสอบสถานะจากวันที่
        if (now.isBefore(startDate)) {
          final remainingTime = _calculateRemainingTime(now, startDate);
          return remainingTime == 'หมดเวลา' ? 'เริ่มแล้ว' : 'มาใน $remainingTime';
        } else if (now.isAfter(endDate)) {
          return 'สิ้นสุดแล้ว';
        } else {
          final remainingTime = _calculateRemainingTime(now, endDate);
          return remainingTime == 'หมดเวลา' ? 'สิ้นสุดแล้ว' : 'เหลือ $remainingTime';
        }
    }
  }
  
  /// คำนวณเวลาที่เหลือระหว่างเวลาปัจจุบันกับเวลาปลายทาง
  static String _calculateRemainingTime(DateTime now, DateTime targetTime) {
    final difference = targetTime.difference(now);
    
    // ถ้าเวลาผ่านไปแล้ว
    if (difference.isNegative) {
      return 'หมดเวลา';
    }
    
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    
    if (days > 0) {
      return '${days}วัน ${hours}ชม ${minutes}นาที';
    } else if (hours > 0) {
      return '${hours}ชม ${minutes}นาที';
    } else if (minutes > 0) {
      return '${minutes}นาที ${seconds}วินาที';
    } else {
      return '${seconds}วินาที';
    }
  }
  
  /// ตรวจสอบสถานะการประมูลจากวันที่
  static String getAuctionStatus({
    required DateTime? startDate,
    required DateTime? endDate,
  }) {
    if (startDate == null || endDate == null) {
      return 'unknown';
    }
    
    final now = DateTime.now();
    
    if (now.isBefore(startDate)) {
      return 'upcoming';
    } else if (now.isAfter(endDate)) {
      return 'completed';
    } else {
      return 'current';
    }
  }
  
  /// จัดรูปแบบวันที่ให้อ่านง่าย
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'ไม่ระบุ';
    
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }
  
  /// จัดรูปแบบวันที่แบบสั้น
  static String formatDateShort(DateTime? dateTime) {
    if (dateTime == null) return 'ไม่ระบุ';
    
    final formatter = DateFormat('dd/MM/yy');
    return formatter.format(dateTime);
  }
  
  /// จัดรูปแบบเวลาแบบสั้น
  static String formatTimeShort(DateTime? dateTime) {
    if (dateTime == null) return 'ไม่ระบุ';
    
    final formatter = DateFormat('HH:mm');
    return formatter.format(dateTime);
  }
} 