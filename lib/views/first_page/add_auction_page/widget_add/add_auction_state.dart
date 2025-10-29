import 'package:flutter/material.dart';
import 'dart:io';
import 'package:e_auction/services/add_auction_service/add_auction_service.dart';
import 'package:intl/intl.dart';

class AddAuctionState {
  // Form Controllers
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController startingPriceController = TextEditingController();
  final TextEditingController minIncrementController = TextEditingController();
  
  // Cost Calculation Controllers
  final TextEditingController costPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  bool showCostCalculation = false;

  
  // Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  // State Variables
  DateTime? startDate;
  DateTime? endDate;
  File? selectedImage;
  bool isPercentage = false;
  double percentageValue = 3.0; // Default 3%
  
  // Quotation Types
  List<Map<String, dynamic>> quotationTypes = [];
  String? selectedQuotationTypeId;
  String? selectedQuotationTypeName;
  String? selectedQuotationTypeCode;
  bool isLoadingQuotationTypes = false;
  
  // Loading State
  bool isSubmitting = false;
  
  // Quantity fields for AS03
  final TextEditingController maxQuantityController = TextEditingController();
  final TextEditingController currentQuantityController = TextEditingController();
  
  // Initialize default values
  void initializeDefaults() {
    startingPriceController.text = '0';
    minIncrementController.text = '0';
    costPriceController.text = '';
    quantityController.text = '';
  }
  
  // Dispose all controllers
  void dispose() {
    productNameController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    startingPriceController.dispose();
    minIncrementController.dispose();
    costPriceController.dispose();
    quantityController.dispose();
    maxQuantityController.dispose();
    currentQuantityController.dispose();
    // ลบการ dispose seller controllers ออกเพราะไม่ใช้แล้ว
  }
  
  // Update selected image
  void updateSelectedImage(File? image) {
    selectedImage = image;
  }
  
  // Update start date
  void updateStartDate(DateTime? date) {
    startDate = date;
  }
  
  // Update end date
  void updateEndDate(DateTime? date) {
    endDate = date;
  }
  
  // Update percentage mode
  void updatePercentageMode(bool isPercentage) {
    this.isPercentage = isPercentage;
  }
  
  // Update percentage value
  void updatePercentageValue(double value) {
    percentageValue = value;
  }
  
  // Update show cost calculation
  void updateShowCostCalculation(bool show) {
    showCostCalculation = show;
  }

  
  // Update quotation types
  void updateQuotationTypes(List<Map<String, dynamic>> types) {
    quotationTypes = types;
  }
  
  // Update selected quotation type
  void updateSelectedQuotationType(String? id, String? name, String? code) {
    selectedQuotationTypeId = id;
    selectedQuotationTypeName = name;
    selectedQuotationTypeCode = code;
  }
  
  // Update loading state for quotation types
  void updateLoadingQuotationTypes(bool loading) {
    isLoadingQuotationTypes = loading;
  }
  
  // Update submitting state
  void updateSubmittingState(bool submitting) {
    isSubmitting = submitting;
  }
  
  // Get current price
  double getCurrentPrice() {
    try {
      // Parse directly (no formatting)
      return double.parse(startingPriceController.text);
    } catch (e) {
      return 0.0;
    }
  }
  
  // Get min increment
  double getMinIncrement() {
    if (isPercentage) {
      return getCurrentPrice() * percentageValue / 100;
    }
    try {
      // Parse directly (no formatting)
      if (minIncrementController.text.isEmpty) {
        return 0.0;
      }
      return double.parse(minIncrementController.text);
    } catch (e) {
      return 0.0;
    }
  }
  
  // Validate form
  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  // Validate auction data using service
  Map<String, dynamic> validateAuctionData() {
    return AddAuctionService.validateAuctionData(getAuctionData());
  }
  
  // Get auction data for API
  Map<String, dynamic> getAuctionData() {
    final data = {
      'product_name': productNameController.text,
      'description': descriptionController.text,
      'notes': notesController.text,
      'starting_price': getCurrentPrice(),
      'min_increment': getMinIncrement(),
      'start_date': startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : '',
      'end_date': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : '',
      'purchase_order_type_id': selectedQuotationTypeId,
      // ลบ seller_name และ seller_phone ออกเพราะไม่ใช้แล้ว
    };
    
    // Add quantity data for AS03 - Hidden
    // if (selectedQuotationTypeCode == 'AS03') {
    //   data['max_quantity'] = maxQuantityController.text.isNotEmpty 
    //       ? int.tryParse(maxQuantityController.text) ?? 0 
    //       : 0;
    //   data['current_quantity'] = currentQuantityController.text.isNotEmpty 
    //       ? int.tryParse(currentQuantityController.text) ?? 0 
    //       : 0;
    // }
    
    // Debug: Print the raw auction data
    print('DEBUG: Raw auction data from form:');
    print('Product Name: ${data['product_name']}');
    print('Description: ${data['description']}');
    print('Notes: ${data['notes']}');
    print('Starting Price: ${data['starting_price']}');
    print('Min Increment: ${data['min_increment']}');
    print('Start Date: ${data['start_date']}');
    print('End Date: ${data['end_date']}');
    print('Purchase Order Type ID: ${data['purchase_order_type_id']}');
    // if (selectedQuotationTypeCode == 'AS03') {
    //   print('Max Quantity: ${data['max_quantity']}');
    //   print('Current Quantity: ${data['current_quantity']}');
    // }
    // ลบ debug prints สำหรับ seller info
    
    return data;
  }

  // Get formatted auction data for API using service
  Future<Map<String, dynamic>> getFormattedAuctionData() async {
    return await AddAuctionService.formatAuctionDataForAPI(getAuctionData());
  }
  
  // Reset form
  void resetForm() {
    productNameController.clear();
    descriptionController.clear();
    notesController.clear();
    startingPriceController.text = '0';
    minIncrementController.text = '100';
    maxQuantityController.clear();
    currentQuantityController.clear();
    // ลบการ clear seller controllers ออกเพราะไม่ใช้แล้ว
    
    startDate = null;
    endDate = null;
    selectedImage = null;
    isPercentage = false;
    percentageValue = 3.0;
    selectedQuotationTypeId = null;
    selectedQuotationTypeName = null;
    selectedQuotationTypeCode = null;
    isSubmitting = false;
  }
  
  // Check if form is complete
  bool isFormComplete() {
    bool basicComplete = productNameController.text.isNotEmpty &&
           descriptionController.text.isNotEmpty &&
           startingPriceController.text.isNotEmpty &&
           // ลบการตรวจสอบ seller fields ออกเพราะไม่ใช้แล้ว
           startDate != null &&
           endDate != null &&
           selectedQuotationTypeId != null;
    
    // Additional validation for AS03 - Hidden
    // if (selectedQuotationTypeCode == 'AS03') {
    //   return basicComplete &&
    //          maxQuantityController.text.isNotEmpty &&
    //          currentQuantityController.text.isNotEmpty;
    // }
    
    return basicComplete;
  }
} 