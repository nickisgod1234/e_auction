import 'package:flutter/material.dart';
import 'widget_add/add_auction_widgets.dart';
import 'widget_add/add_auction_methods.dart';
import 'widget_add/add_auction_state.dart';
import 'promotion_policy_page.dart';
import 'package:url_launcher/url_launcher.dart';

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
    if (_state.selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เพิ่มรูปภาพได้สูงสุด 5 รูป'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final image = await AddAuctionMethods.pickImage();
    if (image != null) {
      _state.addSelectedImage(image);
      setState(() {});
    }
  }

  Future<void> _takePhoto() async {
    if (_state.selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เพิ่มรูปภาพได้สูงสุด 5 รูป'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final image = await AddAuctionMethods.takePhoto();
    if (image != null) {
      _state.addSelectedImage(image);
      setState(() {});
    }
  }
  
  void _removeImage(int index) {
    _state.removeSelectedImage(index);
    setState(() {});
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

  Future<void> _openLineOA() async {
    const lineUrl = 'https://line.me/R/ti/p/@770psqfc';
    final Uri uri = Uri.parse(lineUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try to open Line app directly
        const lineAppUrl = 'line://ti/p/@770psqfc';
        final Uri lineAppUri = Uri.parse(lineAppUrl);
        if (await canLaunchUrl(lineAppUri)) {
          await launchUrl(lineAppUri);
        } else {
          throw Exception('ไม่สามารถเปิด Line ได้');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเปิด Line ได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateQuotationType(String? id, String? name) {
    // Find the selected type to get the code
    String? typeCode;
    if (id != null) {
      final selectedType = _state.quotationTypes.firstWhere(
        (type) => type['id'].toString() == id,
        orElse: () => {'code': ''},
      );
      typeCode = selectedType['code']?.toString();
    }

    _state.updateSelectedQuotationType(id, name, typeCode);
    setState(() {});
  }

  void _showAdminContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'ข้อมูลติดต่อ Admin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'หากมีปัญหาในการใช้งานหรือต้องการความช่วยเหลือ กรุณาติดต่อ Admin ได้ที่:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'อีเมลล์:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'sale@cloudmate-th.com',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _openLineOA,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Line OA:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@770psqfc',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new,
                        color: Colors.green[700],
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
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
                    Icon(
                      Icons.access_time,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เวลาตอบกลับ:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '24 ชั่วโมง',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'ปิด',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // TODO: Implement email opening functionality
            //     Navigator.of(context).pop();
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(
            //         content: Text('เปิดอีเมลล์: nickisgods@gmail.com'),
            //         backgroundColor: Colors.blue,
            //       ),
            //     );
            //   },
            //   icon: const Icon(Icons.email, size: 16),
            //   label: const Text('ส่งอีเมลล์'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.blue[600],
            //     foregroundColor: Colors.white,
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            // ),
          ],
        );
      },
    );
  }

  void _showImageSelectionDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เลือกรูปภาพสินค้า',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                      icon: Icon(Icons.photo_library),
                      label: Text('เลือกรูปจากแกลเลอรี่'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _takePhoto();
                      },
                      icon: Icon(Icons.camera_alt),
                      label: Text('ถ่ายรูปใหม่'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('ยกเลิก'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    // ตรวจสอบว่ามีรูปภาพหรือไม่
    if (_state.selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกรูปภาพสินค้าอย่างน้อย 1 รูปก่อนเพิ่มประมูล'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'เลือกรูป',
            textColor: Colors.white,
            onPressed: () {
              _showImageSelectionDialog();
            },
          ),
        ),
      );
      return;
    }

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
        imageFiles: _state.selectedImages,
      );

      if (result['status'] == 'success') {
        AddAuctionMethods.showSuccessDialog(context);
        _state.resetForm();
      } else {
        AddAuctionMethods.showErrorDialog(
            context, result['message'] ?? 'เกิดข้อผิดพลาด');
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
        actions: [
          IconButton(
            onPressed: () {
              _showAdminContactDialog(context);
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.headset_mic,
                color: Colors.blue[700],
                size: 20,
              ),
            ),
            tooltip: 'ข้อมูลติดต่อ Admin',
          ),
        ],
      ),
      body: Form(
        key: _state.formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Promotion Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'โปรโมชั่นพิเศษ!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ค่าธรรมเนียมเพียง 2% จากยอดชนะ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PromotionPolicyPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ดูรายละเอียด',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Image Section
              AddAuctionWidgets.buildImageSection(
                selectedImages: _state.selectedImages,
                onPickImage: _pickImage,
                onTakePhoto: _takePhoto,
                onRemoveImage: _removeImage,
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
                validator: (value) =>
                    AddAuctionMethods.validateRequired(value, 'ชื่อสินค้า'),
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
                validator: (value) => AddAuctionMethods.validateRequired(
                    value, 'รายละเอียดสินค้า'),
              ),
              AddAuctionWidgets.buildTextField(
                label: 'หมายเหตุ (ถ้ามี)',
                controller: _state.notesController,
                maxLines: 2,
                validator: (value) => null, // Optional
              ),

              // Quantity Fields for AS03 - Hidden
              // if (_state.selectedQuotationTypeCode == 'AS03')
              //   AddAuctionWidgets.buildQuantityFields(
              //     maxQuantityController: _state.maxQuantityController,
              //     currentQuantityController: _state.currentQuantityController,
              //   ),

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
                  onPressed: (_state.isSubmitting || _state.selectedImages.isEmpty) ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _state.selectedImages.isEmpty ? Colors.grey : Colors.blue,
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('กำลังเพิ่มประมูล...'),
                          ],
                        )
                      : Text(
                          _state.selectedImages.isEmpty ? 'กรุณาเลือกรูปภาพก่อน' : 'เพิ่มประมูล',
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
