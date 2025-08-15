import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'widget_add/add_auction_widgets.dart';
import 'widget_add/add_auction_methods.dart';
import 'widget_add/add_auction_state.dart';

class AddAuctionPage extends StatefulWidget {
  const AddAuctionPage({super.key});

  @override
  State<AddAuctionPage> createState() => _AddAuctionPageState();
}

class _AddAuctionPageState extends State<AddAuctionPage> {
  late AddAuctionState _state;

  @override
  void initState() {
    super.initState();
    _state = AddAuctionState();
    _state.initializeDefaults();
    _loadQuotationTypes();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _loadQuotationTypes() async {
    _state.updateLoadingQuotationTypes(true);
    setState(() {});

    try {
      final types = await AddAuctionMethods.loadQuotationTypes();
      _state.updateQuotationTypes(types);
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการโหลดประเภทสินค้า: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _state.updateLoadingQuotationTypes(false);
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final image = await AddAuctionMethods.pickImage();
    if (image != null) {
      _state.updateSelectedImage(image);
      setState(() {});
    }
  }

  Future<void> _takePhoto() async {
    final image = await AddAuctionMethods.takePhoto();
    if (image != null) {
      _state.updateSelectedImage(image);
      setState(() {});
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final date = await AddAuctionMethods.selectDate(context, isStartDate);
    if (date != null) {
      if (isStartDate) {
        _state.updateStartDate(date);
      } else {
        _state.updateEndDate(date);
      }
      setState(() {});
    }
  }

  void _updatePercentageMode(bool isPercentage) {
    _state.updatePercentageMode(isPercentage);
    setState(() {});
  }

  void _updatePercentageValue(double value) {
    _state.updatePercentageValue(value);
    setState(() {});
  }



  void _updateQuotationType(String? id, String? name) {
    _state.updateSelectedQuotationType(id, name);
    setState(() {});
  }

  Future<void> _submitForm() async {
    if (!_state.validateForm()) {
      return;
    }

    // Validate using service
    final validation = _state.validateAuctionData();
    if (!validation['isValid']) {
      final errors = validation['errors'] as Map<String, String>;
      final errorMessage = errors.values.join('\n');
      AddAuctionMethods.showErrorDialog(context, errorMessage);
      return;
    }

    final confirmed = await AddAuctionMethods.showConfirmationDialog(context);
    if (!confirmed) {
      return;
    }

    _state.updateSubmittingState(true);
    setState(() {});

    try {
      final auctionData = await _state.getFormattedAuctionData();
      final result = await AddAuctionMethods.saveAuction(
        auctionData: auctionData,
        imageFile: _state.selectedImage,
      );
      
      if (result['status'] == 'success') {
        AddAuctionMethods.showSuccessDialog(context);
        _state.resetForm();
      } else {
        AddAuctionMethods.showErrorDialog(context, result['message'] ?? 'เกิดข้อผิดพลาด');
      }
    } catch (e) {
      AddAuctionMethods.showErrorDialog(context, 'เกิดข้อผิดพลาด: $e');
    } finally {
      _state.updateSubmittingState(false);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มประมูล'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _state.formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [


                // Image Section
              AddAuctionWidgets.buildImageSection(
                selectedImage: _state.selectedImage,
                onPickImage: _pickImage,
                onTakePhoto: _takePhoto,
              ),

               // Quotation Type Dropdown
              AddAuctionWidgets.buildQuotationTypeDropdown(
                quotationTypes: _state.quotationTypes,
                isLoadingQuotationTypes: _state.isLoadingQuotationTypes,
                selectedQuotationTypeId: _state.selectedQuotationTypeId,
                selectedQuotationTypeName: _state.selectedQuotationTypeName,
                onQuotationTypeChanged: _updateQuotationType,
              ),
              // Product Info Section
              AddAuctionWidgets.buildTextField(
                label: 'ชื่อสินค้า *',
                controller: _state.productNameController,
                validator: (value) => AddAuctionMethods.validateRequired(value, 'ชื่อสินค้า'),
              ),

                // Date Section
              AddAuctionWidgets.buildDateSection(
                startDate: _state.startDate,
                endDate: _state.endDate,
                onSelectStartDate: () => _selectDate(context, true),
                onSelectEndDate: () => _selectDate(context, false),
              ),
              AddAuctionWidgets.buildTextField(
                label: 'รายละเอียดสินค้า *',
                controller: _state.descriptionController,
                maxLines: 3,
                validator: (value) => AddAuctionMethods.validateRequired(value, 'รายละเอียดสินค้า'),
              ),
              AddAuctionWidgets.buildTextField(
                label: 'หมายเหตุ (ถ้ามี)',
                controller: _state.notesController,
                maxLines: 2,
                validator: (value) => null, // Optional
              ),

             

            

            

              // Combined Price Section
              AddAuctionWidgets.buildCombinedPriceSection(
                startingPriceController: _state.startingPriceController,
                minIncrementController: _state.minIncrementController,
                isPercentage: _state.isPercentage,
                percentageValue: _state.percentageValue,
                currentPrice: _state.getCurrentPrice(),
                hasStartingPrice: _state.getCurrentPrice() > 0,
                onStartingPriceChanged: (value) {
                  // อัปเดตราคาปัจจุบันเมื่อราคาเริ่มต้นเปลี่ยน
                  final currentPrice = _state.getCurrentPrice();
                  final minIncrement = _state.getMinIncrement();
                  
                  // ถ้าขั้นต่ำการเพิ่มเกินราคาปัจจุบัน ให้ reset เป็น 0
                  if (minIncrement > currentPrice && currentPrice > 0) {
                    _state.minIncrementController.clear();
                  }
                  
                  setState(() {});
                },
                onMinIncrementChanged: (value) {
                  // อัปเดตขั้นต่ำการเพิ่มเมื่อจำนวนเงินคงที่เปลี่ยน
                  setState(() {});
                },
                onPercentageChanged: _updatePercentageMode,
                onPercentageValueChanged: _updatePercentageValue,
                // เพิ่ม parameters สำหรับการคำนวณราคา
                costPriceController: _state.costPriceController,
                quantityController: _state.quantityController,
                onCostPriceChanged: (value) {
                  setState(() {});
                },
                onQuantityChanged: (value) {
                  setState(() {});
                },
                context: context,
                showCostCalculation: _state.showCostCalculation,
                onShowCostCalculationChanged: (show) {
                  _state.updateShowCostCalculation(show);
                  setState(() {});
                },
              ),

              // Bidder Count Section
              // AddAuctionWidgets.buildBidderCountSection(
              //   bidderCount: 0,
              //   onBidderCountChanged: (value) {}, // ไม่ใช้ callback
              // ),

              // Seller Info Section
              // AddAuctionWidgets.buildSellerInfoSection(
              //   sellerNameController: _state.sellerNameController,
              //   sellerPhoneController: _state.sellerPhoneController,
              // ),

              // Submit Button
              Container(
                margin: const EdgeInsets.all(16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _state.isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _state.isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('กำลังเพิ่มประมูล...'),
                          ],
                        )
                      : const Text(
                          'เพิ่มประมูล',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
} 