import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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

  // Image Section Widget
  static Widget buildImageSection({
    required File? selectedImage,
    required VoidCallback onPickImage,
    required VoidCallback onTakePhoto,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รูปภาพสินค้า',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      selectedImage,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'เพิ่มรูปภาพสินค้า',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
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
                            const Text(
                              'คำนวณราคาขายอัตโนมัติ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Spacer(),
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
                                    'ตัวเลือกเสริม',
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
  static Widget buildSellerInfoSection({
    required TextEditingController sellerNameController,
    required TextEditingController sellerPhoneController,
    required TextEditingController sellerEmailController,
    required TextEditingController sellerAddressController,
    required TextEditingController sellerIdCardController,
    required TextEditingController sellerCompanyController,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: Colors.blue[600]),
              ),
              const SizedBox(width: 12),
              const Text(
                'ข้อมูลส่วนตัวของผู้ขอ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildTextField(
            label: 'ชื่อ-นามสกุล *',
            controller: sellerNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกชื่อ-นามสกุล';
              }
              return null;
            },
          ),
          buildTextField(
            label: 'เบอร์โทรศัพท์ *',
            controller: sellerPhoneController,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกเบอร์โทรศัพท์';
              }
              return null;
            },
          ),
          buildTextField(
            label: 'อีเมล',
            controller: sellerEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกอีเมล';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'กรุณากรอกอีเมลให้ถูกต้อง';
              }
              return null;
            },
          ),
          buildTextField(
            label: 'ที่อยู่ *',
            controller: sellerAddressController,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกที่อยู่';
              }
              return null;
            },
          ),
          buildTextField(
            label: 'เลขบัตรประชาชน *',
            controller: sellerIdCardController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกเลขบัตรประชาชน';
              }
              if (value.length != 13) {
                return 'เลขบัตรประชาชนต้องมี 13 หลัก';
              }
              return null;
            },
          ),
          buildTextField(
            label: 'บริษัท/องค์กร (ถ้ามี)',
            controller: sellerCompanyController,
            validator: (value) {
              return null; // Optional field
            },
          ),
        ],
      ),
    );
  }

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
} 