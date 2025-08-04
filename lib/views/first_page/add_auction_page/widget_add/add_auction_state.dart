import 'package:flutter/material.dart';
import 'dart:io';
import 'package:e_auction/services/add_auction_service/add_auction_service.dart';

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
  
  // Seller Info Controllers
  final TextEditingController sellerNameController = TextEditingController();
  final TextEditingController sellerPhoneController = TextEditingController();
  final TextEditingController sellerEmailController = TextEditingController();
  final TextEditingController sellerAddressController = TextEditingController();
  final TextEditingController sellerIdCardController = TextEditingController();
  final TextEditingController sellerCompanyController = TextEditingController();
  
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
  bool isLoadingQuotationTypes = false;
  
  // Loading State
  bool isSubmitting = false;
  
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
    sellerNameController.dispose();
    sellerPhoneController.dispose();
    sellerEmailController.dispose();
    sellerAddressController.dispose();
    sellerIdCardController.dispose();
    sellerCompanyController.dispose();
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
  

  
  // Update quotation types
  void updateQuotationTypes(List<Map<String, dynamic>> types) {
    quotationTypes = types;
  }
  
  // Update selected quotation type
  void updateSelectedQuotationType(String? id, String? name) {
    selectedQuotationTypeId = id;
    selectedQuotationTypeName = name;
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
    return {
      'product_name': productNameController.text,
      'description': descriptionController.text,
      'notes': notesController.text,
      'starting_price': getCurrentPrice(),
      'min_increment': getMinIncrement(),
      'is_percentage': isPercentage,
      'percentage_value': percentageValue,
      // ไม่ส่ง bidder_count ไป API
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'quotation_type_id': selectedQuotationTypeId,
      'quotation_type_name': selectedQuotationTypeName,
      'seller_name': sellerNameController.text,
      'seller_phone': sellerPhoneController.text,
      'seller_email': sellerEmailController.text,
      'seller_address': sellerAddressController.text,
      'seller_id_card': sellerIdCardController.text,
      'seller_company': sellerCompanyController.text,
      'image_path': selectedImage?.path,
    };
  }

  // Get formatted auction data for API using service
  Map<String, dynamic> getFormattedAuctionData() {
    return AddAuctionService.formatAuctionDataForAPI(getAuctionData());
  }
  
  // Reset form
  void resetForm() {
    productNameController.clear();
    descriptionController.clear();
    notesController.clear();
    startingPriceController.text = '0';
    minIncrementController.text = '100';
    sellerNameController.clear();
    sellerPhoneController.clear();
    sellerEmailController.clear();
    sellerAddressController.clear();
    sellerIdCardController.clear();
    sellerCompanyController.clear();
    
    startDate = null;
    endDate = null;
    selectedImage = null;
    isPercentage = false;
    percentageValue = 3.0;
    selectedQuotationTypeId = null;
    selectedQuotationTypeName = null;
    isSubmitting = false;
  }
  
  // Check if form is complete
  bool isFormComplete() {
    return productNameController.text.isNotEmpty &&
           descriptionController.text.isNotEmpty &&
           startingPriceController.text.isNotEmpty &&
           sellerNameController.text.isNotEmpty &&
           sellerPhoneController.text.isNotEmpty &&
           sellerEmailController.text.isNotEmpty &&
           sellerAddressController.text.isNotEmpty &&
           sellerIdCardController.text.isNotEmpty &&
           startDate != null &&
           endDate != null &&
           selectedQuotationTypeId != null;
  }
} 