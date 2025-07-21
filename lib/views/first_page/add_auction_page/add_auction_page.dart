import 'package:flutter/material.dart';
import 'package:e_auction/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:e_auction/utils/format.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddAuctionPage extends StatefulWidget {
  const AddAuctionPage({super.key});

  @override
  State<AddAuctionPage> createState() => _AddAuctionPageState();
}

class _AddAuctionPageState extends State<AddAuctionPage> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _startingPriceController = TextEditingController();
  final _minIncrementController = TextEditingController();
  
  // ข้อมูลส่วนตัวของผู้ขอ
  final _sellerNameController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  final _sellerEmailController = TextEditingController();
  final _sellerAddressController = TextEditingController();
  final _sellerIdCardController = TextEditingController();
  final _sellerCompanyController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  File? _selectedImage;
  bool _isPercentage = false;
  double _percentageValue = 3.0; // Default 3%
  int _bidderCount = 0; // Default 0
  
  // ประเภทสินค้า
  List<Map<String, dynamic>> _quotationTypes = [];
  String? _selectedQuotationTypeId;
  String? _selectedQuotationTypeName;
  bool _isLoadingQuotationTypes = false;

  @override
  void initState() {
    super.initState();
    // Set default values
    _startingPriceController.text = '0';
    _minIncrementController.text = '100';
    
    // Load quotation types
    _loadQuotationTypes();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _startingPriceController.dispose();
    _minIncrementController.dispose();
    _sellerNameController.dispose();
    _sellerPhoneController.dispose();
    _sellerEmailController.dispose();
    _sellerAddressController.dispose();
    _sellerIdCardController.dispose();
    _sellerCompanyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _loadQuotationTypes() async {
    setState(() {
      _isLoadingQuotationTypes = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost/ERP-Cloudmate/modules/sales/controllers/quotation_type_controller.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Debug: Print raw response
        print('Raw API response: ${response.body}');
        print('Parsed data: $data');
        
        setState(() {
          _quotationTypes = data
            .where((item) {
              // กรองเฉพาะประเภทที่ขึ้นต้นด้วย "A" (Auction types)
              final code = item['quotation_type_code']?.toString() ?? '';
              return code.startsWith('A');
            })
            .map((item) {
              // Debug: Print each item
              print('Processing auction item: $item');
              
              return {
                'id': item['quotation_type_id']?.toString() ?? '',
                'name': item['quotation_type_code']?.toString() ?? '',
                'description': item['description']?.toString() ?? '',
                'code': item['quotation_type_code']?.toString() ?? '',
              };
            }).toList();
          _isLoadingQuotationTypes = false;
        });
        
        print('Loaded ${_quotationTypes.length} quotation types');
        print('Quotation types: $_quotationTypes');
      } else {
        print('Failed to load quotation types: ${response.statusCode}');
        setState(() {
          _isLoadingQuotationTypes = false;
        });
      }
    } catch (e) {
      print('Error loading quotation types: $e');
      setState(() {
        _isLoadingQuotationTypes = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, reset it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _updateMinIncrement() {
    if (_isPercentage && _startingPriceController.text.isNotEmpty) {
      final startingPrice = double.tryParse(_startingPriceController.text) ?? 0;
      final increment = (startingPrice * _percentageValue / 100).round();
      _minIncrementController.text = increment.toString();
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Validate dates
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('กรุณาเลือกช่วงเวลาการประมูล'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('วันสิ้นสุดต้องอยู่หลังวันเริ่มต้น'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show confirmation dialog
      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_shopping_cart, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('ยืนยันการเพิ่มสินค้า'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('คุณต้องการเพิ่มสินค้าประมูลนี้หรือไม่?'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ประเภทสินค้า: ${_selectedQuotationTypeName ?? 'ไม่ระบุ'}'),
                    Text('ชื่อสินค้า: ${_productNameController.text}'),
                    Text('ราคาเริ่มต้น: ${Format.formatCurrency(int.tryParse(_startingPriceController.text) ?? 0)}'),
                    Text('เพิ่มขั้นต่ำ: ${_isPercentage ? '$_percentageValue%' : '${Format.formatCurrency(int.tryParse(_minIncrementController.text) ?? 0)}'}'),
                    Text('เริ่ม: ${DateFormat('dd/MM/yyyy').format(_startDate!)}'),
                    Text('สิ้นสุด: ${DateFormat('dd/MM/yyyy').format(_endDate!)}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveAuction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  void _saveAuction() {
    // TODO: Implement API call to save auction
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เพิ่มสินค้าประมูลสำเร็จ!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate back
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เพิ่มสินค้าประมูล'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // รูปภาพสินค้า
              _buildImageSection(),
              SizedBox(height: 24),

              // ประเภทสินค้า
              _buildQuotationTypeDropdown(),
              SizedBox(height: 16),

              // ชื่อสินค้า
              _buildTextField(
                controller: _productNameController,
                label: 'ชื่อสินค้า *',
                hint: 'กรอกชื่อสินค้า',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อสินค้า';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // ช่วงเวลาการประมูล
              _buildDateSection(),
              SizedBox(height: 16),

              // รายละเอียดสินค้า
              _buildTextField(
                controller: _descriptionController,
                label: 'รายละเอียดสินค้า',
                hint: 'กรอกรายละเอียดสินค้า',
                maxLines: 4,
              ),
              SizedBox(height: 16),

              // หมายเหตุ
              _buildTextField(
                controller: _notesController,
                label: 'หมายเหตุ',
                hint: 'หมายเหตุเพิ่มเติม (ถ้ามี)',
                maxLines: 3,
              ),
              SizedBox(height: 24),

              // ราคาเริ่มต้น
              _buildTextField(
                controller: _startingPriceController,
                label: 'ราคาเริ่มต้น *',
                hint: '0',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกราคาเริ่มต้น';
                  }
                  if (int.tryParse(value) == null) {
                    return 'กรุณากรอกตัวเลขเท่านั้น';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (_isPercentage) {
                    _updateMinIncrement();
                  }
                  // Force rebuild to update current price display
                  setState(() {});
                },
              ),
              SizedBox(height: 16),

              // ราคาปัจจุบัน (แสดงจากราคาเริ่มต้น)
              _buildCurrentPriceSection(),
              SizedBox(height: 16),

              // เพิ่มขั้นต่ำ
              _buildMinIncrementSection(),
              SizedBox(height: 24),

              // จำนวนผู้เสนอประมูล
              _buildBidderCountSection(),
              SizedBox(height: 32),

              // ข้อมูลส่วนตัวของผู้ขอ
              _buildSellerInfoSection(),
              SizedBox(height: 32),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.customTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'เพิ่มสินค้าประมูล',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 20), // เพิ่มระยะห่างด้านล่าง
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รูปภาพสินค้า',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                    SizedBox(height: 8),
                    Text('เพิ่มรูปภาพ', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.photo_library),
                label: Text('เลือกจากแกลเลอรี่'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: Icon(Icons.camera_alt),
                label: Text('ถ่ายภาพ'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ช่วงเวลาการประมูล *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'วันเริ่มต้น',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _startDate != null
                            ? DateFormat('dd/MM/yyyy').format(_startDate!)
                            : 'เลือกวันที่',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'วันสิ้นสุด',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'เลือกวันที่',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMinIncrementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เพิ่มขั้นต่ำ *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: Text('จำนวนเงิน'),
                value: false,
                groupValue: _isPercentage,
                onChanged: (value) {
                  setState(() {
                    _isPercentage = value!;
                    if (!_isPercentage) {
                      _minIncrementController.text = '100';
                    } else {
                      _updateMinIncrement();
                    }
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: Text('เปอร์เซ็นต์'),
                value: true,
                groupValue: _isPercentage,
                onChanged: (value) {
                  setState(() {
                    _isPercentage = value!;
                    if (_isPercentage) {
                      _updateMinIncrement();
                    } else {
                      _minIncrementController.text = '100';
                    }
                  });
                },
              ),
            ),
          ],
        ),
        if (_isPercentage) ...[
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _percentageValue,
                  min: 1.0,
                  max: 25.0,
                  divisions: 24,
                  label: '${_percentageValue.toStringAsFixed(1)}%',
                  onChanged: (value) {
                    setState(() {
                      _percentageValue = value;
                      _updateMinIncrement();
                    });
                  },
                ),
              ),
              SizedBox(width: 16),
              Text(
                '${_percentageValue.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
        SizedBox(height: 8),
        TextFormField(
          controller: _minIncrementController,
          decoration: InputDecoration(
            hintText: _isPercentage ? 'คำนวณอัตโนมัติ' : '100',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixText: _isPercentage ? 'บาท' : 'บาท',
          ),
          keyboardType: TextInputType.number,
          enabled: !_isPercentage,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกเพิ่มขั้นต่ำ';
            }
            if (int.tryParse(value) == null) {
              return 'กรุณากรอกตัวเลขเท่านั้น';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCurrentPriceSection() {
    final startingPrice = int.tryParse(_startingPriceController.text) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ราคาปัจจุบัน',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green[600]),
              SizedBox(width: 12),
              Text(
                Format.formatCurrency(startingPrice),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              Spacer(),
              Text(
                '(เท่ากับราคาเริ่มต้น)',
                style: TextStyle(fontSize: 14, color: Colors.green[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBidderCountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'จำนวนผู้เสนอประมูล',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.people, color: Colors.grey[600]),
              SizedBox(width: 12),
              Text(
                '$_bidderCount คน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text(
                '(เริ่มต้นที่ 0)',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSellerInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // หัวข้อส่วนข้อมูลผู้ขาย
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.blue[600], size: 24),
              SizedBox(width: 12),
              Text(
                'ข้อมูลส่วนตัวของผู้ขอเสนอสินค้า',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // ชื่อ-นามสกุล
        _buildTextField(
          controller: _sellerNameController,
          label: 'ชื่อ-นามสกุล *',
          hint: 'กรอกชื่อ-นามสกุล',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกชื่อ-นามสกุล';
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // เบอร์โทรศัพท์
        _buildTextField(
          controller: _sellerPhoneController,
          label: 'เบอร์โทรศัพท์ *',
          hint: '081-234-5678',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกเบอร์โทรศัพท์';
            }
            if (!RegExp(r'^[0-9-+\s()]+$').hasMatch(value)) {
              return 'กรุณากรอกเบอร์โทรศัพท์ที่ถูกต้อง';
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // อีเมล
        _buildTextField(
          controller: _sellerEmailController,
          label: 'อีเมล',
          hint: 'example@email.com',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'กรุณากรอกอีเมลที่ถูกต้อง';
              }
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // บริษัท/องค์กร
        _buildTextField(
          controller: _sellerCompanyController,
          label: 'บริษัท/องค์กร',
          hint: 'ชื่อบริษัทหรือองค์กร (ถ้ามี)',
        ),
        SizedBox(height: 16),

        // เลขบัตรประชาชน
        _buildTextField(
          controller: _sellerIdCardController,
          label: 'เลขบัตรประชาชน *',
          hint: '1234567890123',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกเลขบัตรประชาชน';
            }
            if (value.length != 13) {
              return 'เลขบัตรประชาชนต้องมี 13 หลัก';
            }
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'กรุณากรอกตัวเลขเท่านั้น';
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // ที่อยู่
        _buildTextField(
          controller: _sellerAddressController,
          label: 'ที่อยู่ *',
          hint: 'กรอกที่อยู่ที่สามารถติดต่อได้',
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกที่อยู่';
            }
            if (value.length < 10) {
              return 'กรุณากรอกที่อยู่ให้ครบถ้วน';
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // ข้อความแจ้งเตือน
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ข้อมูลส่วนตัวจะถูกใช้เพื่อยืนยันความเป็นเจ้าของสินค้าและติดต่อกลับเท่านั้น',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuotationTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ประเภทสินค้า *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoadingQuotationTypes
              ? Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('กำลังโหลดประเภทสินค้า...'),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedQuotationTypeId?.isNotEmpty == true ? _selectedQuotationTypeId : null,
                  decoration: InputDecoration(
                    hintText: 'เลือกประเภทสินค้า',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('เลือกประเภทสินค้า'),
                    ),
                    ..._quotationTypes.map((type) {
                      print('Creating dropdown item for: $type');
                      final itemValue = type['id']?.toString() ?? '';
                      print('Creating dropdown item with value: $itemValue');
                      return DropdownMenuItem<String>(
                        value: itemValue,
                        child: Text(
                          '${type['code']?.toString() ?? 'ไม่ระบุรหัส'} - ${type['description']?.toString() ?? ''}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (String? value) {
                    print('Dropdown changed to: $value');
                    setState(() {
                      _selectedQuotationTypeId = value;
                      if (value != null && value.isNotEmpty) {
                        try {
                          final selectedType = _quotationTypes.firstWhere(
                            (type) => (type['id']?.toString() ?? '') == value,
                          );
                          _selectedQuotationTypeName = selectedType['code']?.toString() ?? 'ไม่ระบุรหัส';
                          print('Found selected type: $selectedType');
                        } catch (e) {
                          print('Error finding selected type: $e');
                          _selectedQuotationTypeName = 'ไม่พบข้อมูล';
                        }
                      } else {
                        _selectedQuotationTypeName = null;
                      }
                    });
                    print('Selected quotation type: $_selectedQuotationTypeId - $_selectedQuotationTypeName');
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาเลือกประเภทสินค้า';
                    }
                    return null;
                  },
                ),
        ),
      ],
    );
  }
} 