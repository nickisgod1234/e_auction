import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:e_auction/utils/format.dart';
import 'add_auction_methods.dart';

// Number Input Formatter for currency
class NumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // ถ้า text ว่างเปล่า ให้ return ค่าว่าง
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // ถ้า text สั้นกว่าเดิม แสดงว่ากำลังลบ ให้ return ค่าเดิม
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }
    
    // Remove all non-digit characters except ฿
    String numericText = newValue.text.replaceAll(RegExp(r'[^\d฿]'), '');
    
    if (numericText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Remove ฿ symbol for parsing
    String cleanNumericText = numericText.replaceAll('฿', '');
    
    if (cleanNumericText.isEmpty) {
      return newValue.copyWith(text: '฿');
    }
    
    // Parse to number and format
    try {
      int number = int.parse(cleanNumericText);
      String formattedText = '฿${NumberFormat('#,###').format(number)}';
      return newValue.copyWith(text: formattedText);
    } catch (e) {
      return newValue;
    }
  }
}

// Number Input Formatter for currency without ฿ symbol
class NumberInputFormatterNoSymbol extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // ถ้า text ว่างเปล่า ให้ return ค่าว่าง
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // ถ้า text สั้นกว่าเดิม แสดงว่ากำลังลบ ให้ return ค่าเดิม
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }
    
    // Remove all non-digit characters
    String numericText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numericText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Parse to number and format
    try {
      int number = int.parse(numericText);
      String formattedText = NumberFormat('#,###').format(number);
      return newValue.copyWith(text: formattedText);
    } catch (e) {
      return newValue;
    }
  }
}

// Simple Number Input Formatter (no formatting, just allow digits)
class SimpleNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only digits
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digit characters
    String numericText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    return newValue.copyWith(text: numericText);
  }
}

class AddAuctionWidgets {
  // Helper function to format number with commas
  static String _formatNumber(String value) {
    if (value.isEmpty) return '0';
    try {
      // Remove any non-digit characters
      final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanValue.isEmpty) return '0';
      final number = int.parse(cleanValue);
      return NumberFormat('#,###').format(number);
    } catch (e) {
      return value;
    }
  }


  // Image Section Widget
  static Widget buildImageSection({
    required List<File> selectedImages,
    required VoidCallback onPickImage,
    required VoidCallback onTakePhoto,
    required Function(int) onRemoveImage,
  }) {
    final canAddMore = selectedImages.length < 5;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'รูปภาพสินค้า',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${selectedImages.length}/5)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(ขั้นต่ำ 1 รูป)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Thumbnail Grid
          if (selectedImages.isNotEmpty)
            Container(
              width: double.infinity,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImages[index],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          
          // Add Image Buttons
          if (canAddMore) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('เลือกจากแกลเลอรี่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTakePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ถ่ายภาพ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'เพิ่มรูปภาพครบ 5 รูปแล้ว',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Date Section Widget
  static Widget buildDateSection({
    required DateTime? startDate,
    required DateTime? endDate,
    required VoidCallback onSelectStartDate,
    required VoidCallback onSelectEndDate,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'วันที่เริ่มและสิ้นสุดการประมูล',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'วันที่เริ่ม',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onSelectStartDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  startDate != null
                                      ? DateFormat('dd/MM/yyyy HH:mm')
                                          .format(startDate)
                                      : 'เลือกวันที่เริ่ม',
                                  style: TextStyle(
                                    color: startDate != null
                                        ? Colors.black
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'วันที่สิ้นสุด',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onSelectEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  endDate != null
                                      ? DateFormat('dd/MM/yyyy HH:mm')
                                          .format(endDate)
                                      : 'เลือกวันที่สิ้นสุด',
                                  style: TextStyle(
                                    color: endDate != null
                                        ? Colors.black
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Text Field Widget
  static Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int? maxLines,
    String? hintText,
    void Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: label.replaceAll(' *', ''),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (label.contains(' *'))
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            onChanged: onChanged,
            inputFormatters: keyboardType == TextInputType.number 
                ? [SimpleNumberInputFormatter()]
                : null,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[600]!),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[600]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Min Increment Section Widget
  static Widget buildMinIncrementSection({
    required bool isPercentage,
    required double percentageValue,
    required TextEditingController minIncrementController,
    required ValueChanged<bool> onPercentageChanged,
    required ValueChanged<double> onPercentageValueChanged,
    required double currentPrice,
    required ValueChanged<String>? onMinIncrementChanged,
  }) {
    // ตรวจสอบว่ามีราคาเริ่มต้นหรือไม่
    bool hasStartingPrice = currentPrice > 0;
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ขั้นต่ำการเพิ่มราคา',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (!hasStartingPrice)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'กรุณากรอกราคาเริ่มต้นก่อนเพื่อตั้งค่าขั้นต่ำการเพิ่ม',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: isPercentage,
                      onChanged: hasStartingPrice ? (value) => onPercentageChanged(value!) : null,
                    ),
                    Text(
                      'เพิ่มแบบระบุจำนวน',
                      style: TextStyle(
                        color: hasStartingPrice ? Colors.black : Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Radio<bool>(
                      value: true,
                      groupValue: isPercentage,
                      onChanged: hasStartingPrice ? (value) => onPercentageChanged(value!) : null,
                    ),
                    Text(
                      'เปอร์เซ็นต์',
                      style: TextStyle(
                        color: hasStartingPrice ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!isPercentage)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: minIncrementController,
                        keyboardType: TextInputType.number,
                        onChanged: hasStartingPrice ? onMinIncrementChanged : null,
                        enabled: hasStartingPrice,
                        validator: (value) => hasStartingPrice 
                            ? AddAuctionMethods.validateMinIncrement(value, currentPrice)
                            : null,
                        inputFormatters: hasStartingPrice ? [SimpleNumberInputFormatter()] : null,
                        decoration: InputDecoration(
                          labelText: 'ขั้นต่ำการเพิ่มราคา (บาท)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixText: '฿',
                          hintText: hasStartingPrice ? null : 'กรุณากรอกราคาเริ่มต้นก่อน',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                minIncrementController.text.isEmpty 
                                    ? 'ขั้นต่ำการเพิ่ม: ฿0'
                                    : 'ขั้นต่ำการเพิ่ม: ฿${NumberFormat('#,###').format(double.tryParse(minIncrementController.text) ?? 0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เปอร์เซ็นต์: ${percentageValue.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: hasStartingPrice ? Colors.black : Colors.grey,
                        ),
                      ),
                      Slider(
                        value: percentageValue,
                        min: 0.1,
                        max: 20.0,
                        divisions: 199,
                        onChanged: hasStartingPrice ? onPercentageValueChanged : null,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calculate, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Text(
                              'ขั้นต่ำการเพิ่ม: ${Format.formatCurrency(currentPrice * percentageValue / 100)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Combined Price Section Widget
  static Widget buildCombinedPriceSection({
    required TextEditingController startingPriceController,
    required TextEditingController minIncrementController,
    required bool isPercentage,
    required double percentageValue,
    required double currentPrice,
    required bool hasStartingPrice,
    required Function(String) onStartingPriceChanged,
    required Function(String) onMinIncrementChanged,
    required ValueChanged<bool> onPercentageChanged,
    required ValueChanged<double> onPercentageValueChanged,
    // เพิ่ม parameters สำหรับการคำนวณราคา
    TextEditingController? costPriceController,
    TextEditingController? quantityController,
    Function(String)? onCostPriceChanged,
    Function(String)? onQuantityChanged,
    required BuildContext context,
    required bool showCostCalculation,
    required ValueChanged<bool> onShowCostCalculationChanged,
  }) {
    // คำนวณขั้นต่ำการเพิ่ม
    double minIncrement;
    if (isPercentage) {
      minIncrement = currentPrice * percentageValue / 100;
    } else {
      try {
        minIncrement = double.tryParse(minIncrementController.text) ?? 0;
      } catch (e) {
        minIncrement = 0;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลราคา',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                // Cost Calculation Section
                if (costPriceController != null && quantityController != null) ...[
                  // Toggle Button
                  Container(
                    width: double.infinity,
                    child: InkWell(
                      onTap: () => onShowCostCalculationChanged(!showCostCalculation),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calculate, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: const Text(
                                'คำนวณราคาขายอัตโนมัติ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    showCostCalculation ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    color: Colors.orange[700],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ตัวเลือก',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Expandable Content
                  if (showCostCalculation) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[25],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          
                          // Cost Price Input
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ราคาทุนต่อชิ้น (บาท)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: costPriceController,
                                      keyboardType: TextInputType.number,
                                      onChanged: onCostPriceChanged,
                                      inputFormatters: [SimpleNumberInputFormatter()],
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        hintText: 'เช่น 10',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'จำนวนชิ้น',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: quantityController,
                                      keyboardType: TextInputType.number,
                                      onChanged: onQuantityChanged,
                                      inputFormatters: [SimpleNumberInputFormatter()],
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        hintText: 'เช่น 100',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Calculation Result
                          Builder(
                            builder: (context) {
                              final costPrice = double.tryParse(costPriceController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
                              final quantity = double.tryParse(quantityController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
                              final totalCost = costPrice * quantity;
                              final suggestedPrice = totalCost * 0.2; // 20% ของต้นทุน
                              final suggestedMinIncrement = suggestedPrice * 0.2; // 20% ของราคาขาย
                              
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.orange[300]!),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('ต้นทุนรวม:', style: TextStyle(fontSize: 12)),
                                        Text('฿${NumberFormat('#,###').format(totalCost)}', 
                                             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('ราคาขายแนะนำ (20%):', style: TextStyle(fontSize: 12)),
                                        Text('฿${NumberFormat('#,###').format(suggestedPrice)}', 
                                             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[700])),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('ขั้นต่ำที่ใช้Bidแนะนำ (20%):', style: TextStyle(fontSize: 12)),
                                        Text('฿${NumberFormat('#,###').format(suggestedMinIncrement)}', 
                                             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[700])),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Apply Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final costPrice = double.tryParse(costPriceController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
                                final quantity = double.tryParse(quantityController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
                                final totalCost = costPrice * quantity;
                                final suggestedPrice = totalCost * 0.2;
                                final suggestedMinIncrement = suggestedPrice * 0.2; // 20% ของราคาขาย
                                
                                if (suggestedPrice > 0) {
                                  startingPriceController.text = suggestedPrice.toInt().toString();
                                  onStartingPriceChanged(suggestedPrice.toInt().toString());
                                  
                                  // ตั้งค่าขั้นต่ำการเพิ่มเป็น 20% ของราคาขาย
                                  if (suggestedMinIncrement > 0) {
                                    // ตั้งค่าขั้นต่ำการเพิ่มในช่อง
                                    minIncrementController.text = suggestedMinIncrement.toInt().toString();
                                    onMinIncrementChanged(suggestedMinIncrement.toInt().toString());
                                    
                                    // แสดง SnackBar แจ้งเตือน
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('ตั้งค่าขั้นต่ำการเพิ่ม: ฿${NumberFormat('#,###').format(suggestedMinIncrement.toInt())} (20% ของราคาขาย)'),
                                        backgroundColor: Colors.blue,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: Icon(Icons.auto_fix_high, size: 16),
                              label: const Text('ใช้ราคาขายแนะนำ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                
                // Starting Price Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'ราคาขายเริ่มต้น (บาท)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: startingPriceController,
                      keyboardType: TextInputType.number,
                      onChanged: onStartingPriceChanged,
                      validator: AddAuctionMethods.validatePrice,
                      inputFormatters: [SimpleNumberInputFormatter()],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Current Price Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ราคาปัจจุบัน:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        Format.formatCurrency(currentPrice),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Min Increment Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ขั้นต่ำการเพิ่มราคา',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Radio Buttons
                    Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: isPercentage,
                          onChanged: hasStartingPrice ? (value) => onPercentageChanged(value!) : null,
                        ),
                        Text(
                          'จำนวนเงินคงที่',
                          style: TextStyle(
                            color: hasStartingPrice ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Radio<bool>(
                          value: true,
                          groupValue: isPercentage,
                          onChanged: hasStartingPrice ? (value) => onPercentageChanged(value!) : null,
                        ),
                        Text(
                          'เปอร์เซ็นต์',
                          style: TextStyle(
                            color: hasStartingPrice ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Input Fields
                    if (isPercentage) ...[
                      // Percentage Slider
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${percentageValue.toInt()}%'),
                              Text('฿${NumberFormat('#,###').format(currentPrice * percentageValue / 100)}'),
                            ],
                          ),
                          Slider(
                            value: percentageValue,
                            min: 1.0,
                            max: 20.0,
                            divisions: 19, // เปลี่ยนจาก 199 เป็น 19 เพื่อให้เพิ่มทีละ 1
                            onChanged: hasStartingPrice ? (value) => onPercentageValueChanged(value) : null,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('1%'),
                              Text('20%'),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      // Fixed Amount Input
                      TextFormField(
                        controller: minIncrementController,
                        keyboardType: TextInputType.number,
                        onChanged: hasStartingPrice ? onMinIncrementChanged : null,
                        enabled: hasStartingPrice,
                        validator: (value) => hasStartingPrice
                            ? AddAuctionMethods.validateMinIncrement(value, currentPrice)
                            : null,
                        inputFormatters: hasStartingPrice ? [SimpleNumberInputFormatter()] : null,
                        decoration: InputDecoration(
                          labelText: 'ขั้นต่ำการเพิ่มราคา (บาท)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixText: '฿',
                          hintText: hasStartingPrice ? null : 'กรุณากรอกราคาเริ่มต้นก่อน',
                        ),
                      ),
                    ],
                    
                    // Info Card
                    if (hasStartingPrice) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ขั้นต่ำการเพิ่ม: ${Format.formatCurrency(minIncrement)}${isPercentage ? ' (${percentageValue.toInt()}%)' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'กรุณากรอกราคาเริ่มต้นก่อนเพื่อตั้งค่าขั้นต่ำการเพิ่ม',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bulk Sale Section for AS03 Widget
  static Widget buildBulkSaleSection({
    required TextEditingController startingPriceController,
    required TextEditingController maxQuantityController,
    required Function(String) onStartingPriceChanged,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: Colors.orange[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'การขายสินค้าแบบเหมา',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ขายเป็นชุด ราคาเดียว ไม่มีการประมูล',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ตัวอย่าง: ขายเก้าอี้ 20 ตัว ราคาเหมา 1,000 บาท - ผู้ซื้อจะลงชื่อเพื่อจองสินค้า',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quantity Fields
          const Text(
            'จำนวนสินค้า',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          buildTextField(
            label: 'จำนวนสินค้าทั้งหมด *',
            controller: maxQuantityController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกจำนวนสินค้าทั้งหมด';
              }
              final quantity = int.tryParse(value);
              if (quantity == null || quantity <= 0) {
                return 'กรุณากรอกจำนวนสินค้าที่ถูกต้อง';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Bulk Price Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'ราคาเหมาทั้งชุด (บาท)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: startingPriceController,
                  keyboardType: TextInputType.number,
                  onChanged: onStartingPriceChanged,
                  validator: AddAuctionMethods.validatePrice,
                  inputFormatters: [SimpleNumberInputFormatter()],
                  decoration: InputDecoration(
                    hintText: 'เช่น 1000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    prefixText: '฿',
                  ),
                ),
                const SizedBox(height: 12),
                // Price Display
                if (startingPriceController.text.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final price = double.tryParse(startingPriceController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
                      final quantity = int.tryParse(maxQuantityController.text) ?? 0;
                      final pricePerUnit = quantity > 0 ? price / quantity : 0;
                      
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[50]!, Colors.orange[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ราคาเหมาทั้งชุด:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  Format.formatCurrency(price),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            if (quantity > 0) ...[
                              const SizedBox(height: 8),
                              Divider(color: Colors.orange[200]),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ราคาต่อชิ้น (${NumberFormat('#,###').format(quantity)} ชิ้น):',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    Format.formatCurrency(pricePerUnit),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Quantity Fields for AS03 Widget (Legacy - kept for backward compatibility)
  static Widget buildQuantityFields({
    required TextEditingController maxQuantityController,
    required TextEditingController currentQuantityController,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลจำนวนสินค้า',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: buildTextField(
                  label: 'จำนวนสินค้าสูงสุด *',
                  controller: maxQuantityController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกจำนวนสินค้าสูงสุด';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'กรุณากรอกจำนวนสินค้าที่ถูกต้อง';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: buildTextField(
                  label: 'จำนวนสินค้าปัจจุบัน *',
                  controller: currentQuantityController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกจำนวนสินค้าปัจจุบัน';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'กรุณากรอกจำนวนสินค้าที่ถูกต้อง';
                    }
                    final maxQuantity = int.tryParse(maxQuantityController.text) ?? 0;
                    if (quantity > maxQuantity) {
                      return 'จำนวนสินค้าปัจจุบันต้องไม่เกินจำนวนสูงสุด';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Bidder Count Section Widget
  static Widget buildBidderCountSection({
    required int bidderCount,
    required ValueChanged<int> onBidderCountChanged,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'จำนวนผู้ประมูลขั้นต่ำ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'จำนวนผู้ประมูล:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '0 คน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Seller Info Section Widget
  // static Widget buildSellerInfoSection({
  //   required TextEditingController sellerNameController,
  //   required TextEditingController sellerPhoneController,
  // }) {
  //   return Container(
  //     margin: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: Colors.blue.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Icon(Icons.person, color: Colors.blue[600]),
  //             ),
  //             const SizedBox(width: 12),
  //             const Text(
  //               'ข้อมูลส่วนตัวของผู้ขอ',
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         buildTextField(
  //           label: 'ชื่อ-นามสกุล *',
  //           controller: sellerNameController,
  //           validator: (value) {
  //             if (value == null || value.isEmpty) {
  //               return 'กรุณากรอกชื่อ-นามสกุล';
  //             }
  //             return null;
  //           },
  //         ),
  //         buildTextField(
  //           label: 'เบอร์โทรศัพท์ *',
  //           controller: sellerPhoneController,
  //           keyboardType: TextInputType.phone,
  //           validator: (value) {
  //             if (value == null || value.isEmpty) {
  //               return 'กรุณากรอกเบอร์โทรศัพท์';
  //             }
  //             return null;
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Quotation Type Dropdown Widget
  static Widget buildQuotationTypeDropdown({
    required List<Map<String, dynamic>> quotationTypes,
    required bool isLoadingQuotationTypes,
    required String? selectedQuotationTypeId,
    required String? selectedQuotationTypeName,
    required Function(String?, String?) onQuotationTypeChanged,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ประเภทสินค้า',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedQuotationTypeId,
                hint: isLoadingQuotationTypes
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('กำลังโหลด...'),
                        ],
                      )
                    : const Text('เลือกประเภทสินค้า'),
                isExpanded: true,
                items: quotationTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['id'].toString(),
                    child: Text('${type['code']} - ${type['name']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  final selectedType = quotationTypes.firstWhere(
                    (type) => type['id'].toString() == value,
                    orElse: () => {'id': '', 'name': ''},
                  );
                  onQuotationTypeChanged(value, selectedType['name']);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build Delivery Section
  static Widget buildDeliverySection({
    required String? deliveryType,
    required TextEditingController deliveryPriceController,
    required TextEditingController deliveryPricePerKmController,
    required Function(String?) onDeliveryTypeChanged,
    required Function(String) onDeliveryPriceChanged,
    required Function(String) onDeliveryPricePerKmChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_shipping,
                  color: Colors.blue[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การจัดส่ง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'เลือกประเภทการจัดส่ง',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Delivery Type Dropdown
          DropdownButtonFormField<String>(
            value: deliveryType,
            decoration: InputDecoration(
              labelText: 'ประเภทการจัดส่ง',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              prefixIcon: Icon(Icons.delivery_dining, color: Colors.blue[700]),
            ),
            items: [
              DropdownMenuItem<String>(
                value: 'free',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Text('จัดส่งฟรี'),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'fixed',
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Text('ส่งราคาเหมา'),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'distance',
                child: Row(
                  children: [
                    Icon(Icons.straighten, color: Colors.purple[600], size: 20),
                    const SizedBox(width: 8),
                    Text('ส่งตามระยะทาง'),
                  ],
                ),
              ),
            ],
            onChanged: onDeliveryTypeChanged,
          ),
          
          // Conditional Fields based on delivery type
          if (deliveryType == 'fixed') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: deliveryPriceController,
              keyboardType: TextInputType.number,
              onChanged: onDeliveryPriceChanged,
              decoration: InputDecoration(
                labelText: 'ราคาเหมา (บาท) *',
                hintText: 'เช่น 100',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                prefixIcon: Icon(Icons.currency_exchange, color: Colors.orange[600]),
                suffixText: '฿',
              ),
              inputFormatters: [SimpleNumberInputFormatter()],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: deliveryPriceController,
              builder: (context, value, child) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calculate, size: 20, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ราคาการจัดส่ง',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '฿${_formatNumber(value.text)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          
          if (deliveryType == 'distance') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: deliveryPricePerKmController,
              keyboardType: TextInputType.number,
              onChanged: onDeliveryPricePerKmChanged,
              decoration: InputDecoration(
                labelText: 'ราคาต่อ กม. (บาท) *',
                hintText: 'เช่น 10',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                prefixIcon: Icon(Icons.attach_money, color: Colors.purple[600]),
                suffixText: '฿/กม.',
              ),
              inputFormatters: [SimpleNumberInputFormatter()],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: deliveryPricePerKmController,
              builder: (context, value, child) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calculate, size: 20, color: Colors.purple[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ราคาการจัดส่ง',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '฿${_formatNumber(value.text)} ต่อ กม.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.purple[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ราคาจะคำนวณตามระยะทางจริงที่ลูกค้าต้องการจัดส่ง',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (deliveryType == 'free') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'จัดส่งฟรีทั่วประเทศ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
} 