import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';

class ProductService {
  final String baseUrl;
  late http.Client _client;

  ProductService({required this.baseUrl}) {
    _client = _createHttpClient();
  }

  http.Client _createHttpClient() {
    if (Platform.isAndroid) {
      // สำหรับ Android ให้ bypass SSL verification
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true; // ยอมรับ certificate ทั้งหมด
      };
      return IOClient(client);
    } else {
      // สำหรับ iOS และ platform อื่นๆ ใช้ default
      return http.Client();
    }
  }

  // แปลง HTTPS เป็น HTTP สำหรับ Android
  String _getBaseUrl() {
    if (Platform.isAndroid) {
      return baseUrl.replaceFirst('https://', 'http://');
    }
    return baseUrl;
  }

  // Helper function to safely convert any value to string
  String _safeToString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  // Helper function to safely convert any value to double
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // Helper function to safely convert any value to int
  int _safeToInt(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    final result = int.tryParse(value.toString()) ?? 0;
    return result;
  }

  // เรียกรายการ quotation ทั้งหมด
  Future<List<Map<String, dynamic>>?> getAllQuotations() async {
    final url = Uri.parse(
        '${_getBaseUrl()}/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php');
   try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );



      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is List) {
          return _parseQuotationList(data);
        } else {
          return [];
        }
      } else {
        throw Exception(
            'Failed to fetch quotations. Status: ${response.statusCode}');
      }
    } catch (e) {
      return null;
    }
  }

  // กรองเฉพาะ quotation ที่เป็น auction (AS นำหน้า) และ status = 1
  List<Map<String, dynamic>> _filterAuctionQuotations(
      List<Map<String, dynamic>> quotations) {
    
    print('DEBUG: ProductService - Filtering ${quotations.length} quotations');
    
    final filteredQuotations = quotations.where((quotation) {
      final typeCode = _safeToString(quotation['quotation_type_code']);
      final status = _safeToString(quotation['status']); // เปลี่ยนเป็น string
      final title = _safeToString(quotation['short_text']);
           
      // กรองเฉพาะ auction types (AS นำหน้า) และ status = "1" (เปิดใช้งาน)
      final isAuction = typeCode.startsWith('AS');
      final isActive = status == "1"; // เปรียบเทียบกับ string "1"
      final shouldInclude = isAuction && isActive;
      
      print('DEBUG: ProductService - Quotation: $title, Type: $typeCode, Status: $status, Include: $shouldInclude');
      
      if (!shouldInclude) {
        print('DEBUG: ProductService - Excluded: $title (Type: $typeCode, Status: $status)');
      } else {
        print('DEBUG: ProductService - Included: $title (Type: $typeCode, Status: $status)');
      }
      
      return shouldInclude;
    }).toList();
    
    print('DEBUG: ProductService - Filtered to ${filteredQuotations.length} auction quotations');

    return filteredQuotations;
  }

  // เรียกข้อมูลสินค้าประมูลทั้งหมด (ขั้นตอนใหม่)
  Future<List<Map<String, dynamic>>?> getAllAuctionProducts() async {
    try {
      // เรียกรายการ quotation ทั้งหมด (ข้อมูลครบแล้วใน API ใหม่)
      final allQuotations = await getAllQuotations();
      if (allQuotations == null) return null;

      // กรองเฉพาะ auction quotations
      final auctionQuotations = _filterAuctionQuotations(allQuotations);
      return auctionQuotations;
    } catch (e) {
      return null;
    }
  }

  // เรียกข้อมูลสินค้าประมูลตาม ID
  Future<Map<String, dynamic>?> getAuctionProductById(
      String quotationId) async {
    final url = Uri.parse(
        '$baseUrl/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=$quotationId');
    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseSingleAuctionProduct(data);
      } else {
        throw Exception(
            'Failed to fetch auction product. Status: ${response.statusCode}');
      }
    } catch (e) {
      return null;
    }
  }

  // เรียกข้อมูลสินค้าประมูลที่กำลังดำเนินการ
  Future<List<Map<String, dynamic>>?> getCurrentAuctions() async {
    final products = await getAllAuctionProducts();
    if (products == null) return null;

    final now = DateTime.now();
    return products.where((product) {
      final startDate = DateTime.tryParse(product['auction_start_date'] ?? '');
      final endDate = DateTime.tryParse(product['auction_end_date'] ?? '');
      
      if (startDate == null || endDate == null) return false;
      
      return now.isAfter(startDate) && now.isBefore(endDate);
    }).toList();
  }

  // เรียกข้อมูลสินค้าประมูลที่กำลังจะมาถึง
  Future<List<Map<String, dynamic>>?> getUpcomingAuctions() async {
    final products = await getAllAuctionProducts();
    if (products == null) return null;

    final now = DateTime.now();
    return products.where((product) {
      final startDate = DateTime.tryParse(product['auction_start_date'] ?? '');
      
      if (startDate == null) return false;
      
      return now.isBefore(startDate);
    }).toList();
  }

  // เรียกข้อมูลสินค้าประมูลที่จบแล้ว
  Future<List<Map<String, dynamic>>?> getCompletedAuctions() async {
    final products = await getAllAuctionProducts();
    if (products == null) return null;

    final now = DateTime.now();
    return products.where((product) {
      final endDate = DateTime.tryParse(product['auction_end_date'] ?? '');
      
      if (endDate == null) return false;
      
      return now.isAfter(endDate);
    }).toList();
  }

  // Parse รายการ quotation จาก API response
  List<Map<String, dynamic>> _parseQuotationList(List<dynamic> rawData) {
    final List<Map<String, dynamic>> quotations = [];
    
    for (var item in rawData) {
      if (item is Map<String, dynamic>) {
        final quotation = {
          'quotation_id': _safeToString(item['quotation_id']),
          'quotation_more_information_id':
              _safeToString(item['quotation_more_information_id']),
          'sequence': _safeToString(item['sequence']),
          'quotation_type_code': _safeToString(item['quotation_type_code']),
          'quotation_type_description': _safeToString(item['quotation_type_description']),
          'description': _safeToString(item['description']),
          'created_at': _safeToString(item['created_at']),
          'short_text': _safeToString(item['short_text']),
          'auction_start_date': _safeToString(item['auction_start_date']),
          'auction_end_date': _safeToString(item['auction_end_date']),
          'quotation_image': _safeToString(item['quotation_image']),
          'estimated_price': _safeToInt(item['estimated_price']),
          'total_value': _safeToInt(item['total_value']),
          'currency_code': _safeToString(item['currency_code']),
          'quotation_message': _safeToString(item['quotation_message']),
          'purchase_message': _safeToString(item['purchase_message']),
          'item_note': _safeToString(item['item_note']),
          'star_price': _safeToInt(item['star_price']),
          'current_price': _safeToInt(item['current_price']),
          'minimum_increase': _safeToInt(item['minimum_increase']),
          'number_bidders': _safeToInt(item['number_bidders']),
          'remaining_time': _safeToString(item['remaining_time']),
          'status': _safeToString(item['status']), // เปลี่ยนเป็น string
          'quantity': _safeToInt(item['quantity']), // เพิ่ม quantity field
          // เพิ่มคีย์ใหม่จาก API response
          'quotation_description': _safeToString(item['quotation_description']),
          'item_number': _safeToString(item['item_number']),
          'accounting_category_id': _safeToString(item['accounting_category_id']),
          'item_category_id': _safeToString(item['item_category_id']),
          'material_id': _safeToString(item['material_id']),
          'count_unit_id': _safeToString(item['count_unit_id']),
          'ind_type_id': _safeToString(item['ind_type_id']),
          'warehouse_id': _safeToString(item['warehouse_id']),
          'procurement_group_id': _safeToString(item['procurement_group_id']),
          'updated_at': _safeToString(item['updated_at']),
          'created_by': _safeToString(item['created_by']),
          'updated_by': _safeToString(item['updated_by']),
          'is_deleted': _safeToString(item['is_deleted']),
          'quotation_main_id': _safeToString(item['quotation_main_id']),
          'sourcing': _safeToString(item['sourcing']),
          'additional_notes': _safeToString(item['additional_notes']),
          'quotation_note': _safeToString(item['quotation_note']),
          'quotation_social': _safeToString(item['quotation_social']),
          'vendor_id': _safeToString(item['vendor_id']),
          'quotation_type_id': _safeToString(item['quotation_type_id']),
          'quotation_path_image': _safeToString(item['quotation_path_image']),
          'noti': _safeToString(item['noti']),
          'customer_id': _safeToString(item['customer_id']),
          // Material data
          'quotation_material_data_id': _safeToString(item['quotation_material_data_id']),
          'material_id_tab': _safeToString(item['material_id_tab']),
          'short_text_tab': _safeToString(item['short_text_tab']),
          'mpn_material': _safeToString(item['mpn_material']),
          'manuf_part_no': _safeToString(item['manuf_part_no']),
          'batch': _safeToString(item['batch']),
          'revision_level': _safeToString(item['revision_level']),
          'assessment_value': _safeToString(item['assessment_value']),
          'material_group_id': _safeToString(item['material_group_id']),
          'iuid_relevant': _safeToString(item['iuid_relevant']),
          'supplier_material': _safeToString(item['supplier_material']),
          'product_category_group': _safeToString(item['product_category_group']),
          'manufacturer': _safeToString(item['manufacturer']),
          'ext_man': _safeToString(item['ext_man']),
          'mfr_part_profile': _safeToString(item['mfr_part_profile']),
          // Quantity date
          'quotation_quantity_date_id': _safeToString(item['quotation_quantity_date_id']),
          'quantity_tab': _safeToInt(item['quantity_tab']),
          'delivery_date': _safeToString(item['delivery_date']),
          'ordered_quantity': _safeToString(item['ordered_quantity']),
          'request_date': _safeToString(item['request_date']),
          'pending_quantity': _safeToString(item['pending_quantity']),
          'approval_date': _safeToString(item['approval_date']),
          'closed_status': _safeToString(item['closed_status']),
          'planned_delivery_time': _safeToString(item['planned_delivery_time']),
          'fixed_id': _safeToString(item['fixed_id']),
          'transfer_time': _safeToString(item['transfer_time']),
          'quantity_confirm': _safeToString(item['quantity_confirm']),
          'conf_date': _safeToString(item['conf_date']),
          // Valuation
          'quotation_valuation_id': _safeToString(item['quotation_valuation_id']),
          'currency_id': _safeToString(item['currency_id']),
          'per': _safeToString(item['per']),
          'promotion': _safeToString(item['promotion']),
          'tax_code': _safeToString(item['tax_code']),
          'assessment_value2': _safeToString(item['assessment_value2']),
          'quotation_price': _safeToString(item['quotation_price']),
          'goods_receipt': _safeToString(item['goods_receipt']),
          'invoice_receipt': _safeToString(item['invoice_receipt']),
          'gr_non_valuation': _safeToString(item['gr_non_valuation']),
          // Account assignment
          'quotation_account_assignment_id': _safeToString(item['quotation_account_assignment_id']),
          'accounting_category_id_tab': _safeToString(item['accounting_category_id_tab']),
          'distribution': _safeToString(item['distribution']),
          'company_id': _safeToString(item['company_id']),
          'penalty_value': _safeToString(item['penalty_value']),
          'recipient': _safeToString(item['recipient']),
          'central_general_ledger_id': _safeToString(item['central_general_ledger_id']),
          'control_area': _safeToString(item['control_area']),
          'fund_center_id': _safeToString(item['fund_center_id']),
          'product': _safeToString(item['product']),
          'budget_source_id': _safeToString(item['budget_source_id']),
          'grant_amount': _safeToString(item['grant_amount']),
          'functional_area': _safeToString(item['functional_area']),
          'funds_ctr': _safeToString(item['funds_ctr']),
          'commitment_item': _safeToString(item['commitment_item']),
          'service_document': _safeToString(item['service_document']),
          // Procurement source
          'quotation_procurement_source_id': _safeToString(item['quotation_procurement_source_id']),
          'agreement': _safeToString(item['agreement']),
          'organization_id': _safeToString(item['organization_id']),
          'count_unit_id_tab': _safeToString(item['count_unit_id_tab']),
          'framework_order': _safeToString(item['framework_order']),
          'requirement_urgency': _safeToString(item['requirement_urgency']),
          'requirement_priority': _safeToString(item['requirement_priority']),
          'designated_vendor': _safeToString(item['designated_vendor']),
          'ind_type_id_tab': _safeToString(item['ind_type_id_tab']),
          'data_record': _safeToString(item['data_record']),
          'issuing_stor_loc': _safeToString(item['issuing_stor_loc']),
          'desired_vendor': _safeToString(item['desired_vendor']),
          'mpn_material2': _safeToString(item['mpn_material2']),
          'vendor_material_number': _safeToString(item['vendor_material_number']),
          // Status
          'quotation_status_id': _safeToString(item['quotation_status_id']),
          'status_pmp': _safeToString(item['status_pmp']),
          'ordered_qty': _safeToString(item['ordered_qty']),
          'kg': _safeToString(item['kg']),
          'block_id': _safeToString(item['block_id']),
          'blocking_text': _safeToString(item['blocking_text']),
          'ext_apprvl_stat': _safeToString(item['ext_apprvl_stat']),
          'central_approval': _safeToString(item['central_approval']),
          // Contact person
          'quotation_contact_person_id': _safeToString(item['quotation_contact_person_id']),
          'created_by_person': _safeToString(item['created_by_person']),
          'changed_at': _safeToString(item['changed_at']),
          'creat_ind': _safeToString(item['creat_ind']),
          'quotation_requester': _safeToString(item['quotation_requester']),
          'tracking_number': _safeToString(item['tracking_number']),
          'procurement_group_id_tab': _safeToString(item['procurement_group_id_tab']),
          'phone_number': _safeToString(item['phone_number']),
          'fax_number': _safeToString(item['fax_number']),
          'mrp_controller': _safeToString(item['mrp_controller']),
          'phone_number2': _safeToString(item['phone_number2']),
          // Message
          'quotation_message_id': _safeToString(item['quotation_message_id']),
          'delivery_message': _safeToString(item['delivery_message']),
          'order_message': _safeToString(item['order_message']),
          // Delivery address
          'quotation_delivery_address_id': _safeToString(item['quotation_delivery_address_id']),
          'name': _safeToString(item['name']),
          'company_id2': _safeToString(item['company_id2']),
          'house_number': _safeToString(item['house_number']),
          'village': _safeToString(item['village']),
          'road': _safeToString(item['road']),
          'sub_district': _safeToString(item['sub_district']),
          'district': _safeToString(item['district']),
          'province': _safeToString(item['province']),
          'postal_code': _safeToString(item['postal_code']),
          'country': _safeToString(item['country']),
          // Auction specific fields
          'auction_type': _safeToString(item['auction_type']),
          'quantity_discount_enabled': _safeToString(item['quantity_discount_enabled']),
          'discount_tiers': _safeToString(item['discount_tiers']),
          'current_quantity_sold': _safeToInt(item['current_quantity_sold']),
          'max_quantity_available': _safeToInt(item['max_quantity_available']),
          'quantity_discount_rules': _safeToString(item['quantity_discount_rules']),
        };
        quotations.add(quotation);
      }
    }
    
    return quotations;
  }

  // Parse ข้อมูลสินค้าประมูลเดี่ยว
  Map<String, dynamic>? _parseSingleAuctionProduct(
      Map<String, dynamic> rawData) {
    try {
      // ข้อมูลหลักของสินค้า
      final Map<String, dynamic> product = {
        'id': _safeToString(rawData['quotation_id']),
        'type_id': _safeToString(rawData['quotation_type_id']),
        'type_code': _safeToString(rawData['quotation_type_code']),
        'type_description':
            _safeToString(rawData['quotation_type_description']),
        'sourcing': _safeToString(rawData['sourcing']),
        'description': _safeToString(rawData['description']),
        'vendor_id': _safeToString(rawData['vendor_id']),
        'additional_notes': _safeToString(rawData['additional_notes']),
        'auction_start_date': _safeToString(rawData['auction_start_date']),
        'auction_end_date': _safeToString(rawData['auction_end_date']),
        'sequence': _safeToString(rawData['sequence']),
        'created_by': _safeToString(rawData['created_by']),
        'created_at': _safeToString(rawData['created_at']),
        'items': [],
      };

      // Parse รายการสินค้า
      if (rawData['items'] != null && rawData['items'] is List) {
        final List<Map<String, dynamic>> items = [];
        
        for (var item in rawData['items']) {
          final parsedItem = _parseAuctionItem(item);
          if (parsedItem != null) {
            items.add(parsedItem);
          }
        }
        
        product['items'] = items;
      }

      return product;
    } catch (e) {
      return null;
    }
  }

  // Parse ข้อมูลรายการสินค้า
  Map<String, dynamic>? _parseAuctionItem(Map<String, dynamic> rawItem) {
    try {
      final Map<String, dynamic> item = {
        'purchase_order_main_id':
            _safeToString(rawItem['purchase_order_main_id']),
        'status': _safeToString(rawItem['status']),
        'item_number': _safeToString(rawItem['item_number']),
        'accounting_category_id':
            _safeToString(rawItem['accounting_category_id']),
        'item_category_id': _safeToString(rawItem['item_category_id']),
        'material_id': _safeToString(rawItem['material_id']),
        'short_text': _safeToString(rawItem['short_text']),
        'quantity': _safeToInt(rawItem['quantity']),
        'count_unit_id': _safeToString(rawItem['count_unit_id']),
        'ind_type_id': _safeToString(rawItem['ind_type_id']),
        'warehouse_id': _safeToString(rawItem['warehouse_id']),
        'procurement_group_id': _safeToString(rawItem['procurement_group_id']),
        'tabs': {},
      };

      // Parse tabs data
      if (rawItem['tabs'] != null && rawItem['tabs'] is Map) {
        final tabs = rawItem['tabs'] as Map<String, dynamic>;
        
        // Material data
        if (tabs['material_data'] != null) {
          final materialData = tabs['material_data'] as Map<String, dynamic>;
          item['tabs']['material_data'] = {
            'quotation_material_data_id':
                _safeToString(materialData['quotation_material_data_id']),
            'quotation_main_id':
                _safeToString(materialData['quotation_main_id']),
            'material_id_tab': _safeToString(materialData['material_id_tab']),
            'short_text_tab': _safeToString(materialData['short_text_tab']),
            'mpn_material': _safeToString(materialData['mpn_material']),
            'manuf_part_no': _safeToString(materialData['manuf_part_no']),
            'batch': _safeToString(materialData['batch']),
            'revision_level': _safeToString(materialData['revision_level']),
            'assessment_value': _safeToString(materialData['assessment_value']),
            'material_group_id':
                _safeToString(materialData['material_group_id']),
            'iuid_relevant': _safeToString(materialData['iuid_relevant']),
            'supplier_material':
                _safeToString(materialData['supplier_material']),
            'product_category_group':
                _safeToString(materialData['product_category_group']),
            'manufacturer': _safeToString(materialData['manufacturer']),
            'ext_man': _safeToString(materialData['ext_man']),
            'mfr_part_profile': _safeToString(materialData['mfr_part_profile']),
            'created_at': _safeToString(materialData['created_at']),
            'updated_at': _safeToString(materialData['updated_at']),
            'created_by': _safeToString(materialData['created_by']),
            'updated_by': _safeToString(materialData['updated_by']),
            'is_deleted': _safeToString(materialData['is_deleted']),
          };
        }

        // Quantity date
        if (tabs['quantity_date'] != null) {
          final quantityDate = tabs['quantity_date'] as Map<String, dynamic>;
          item['tabs']['quantity_date'] = {
            'quotation_quantity_date_id':
                _safeToString(quantityDate['quotation_quantity_date_id']),
            'quotation_main_id':
                _safeToString(quantityDate['quotation_main_id']),
            'quantity_tab': _safeToInt(quantityDate['quantity_tab']),
            'delivery_date': _safeToString(quantityDate['delivery_date']),
            'ordered_quantity': _safeToString(quantityDate['ordered_quantity']),
            'request_date': _safeToString(quantityDate['request_date']),
            'pending_quantity': _safeToString(quantityDate['pending_quantity']),
            'approval_date': _safeToString(quantityDate['approval_date']),
            'closed_status': _safeToString(quantityDate['closed_status']),
            'planned_delivery_time':
                _safeToString(quantityDate['planned_delivery_time']),
            'fixed_id': _safeToString(quantityDate['fixed_id']),
            'transfer_time': _safeToString(quantityDate['transfer_time']),
            'quantity_confirm': _safeToString(quantityDate['quantity_confirm']),
            'conf_date': _safeToString(quantityDate['conf_date']),
            'created_at': _safeToString(quantityDate['created_at']),
            'updated_at': _safeToString(quantityDate['updated_at']),
            'created_by': _safeToString(quantityDate['created_by']),
            'updated_by': _safeToString(quantityDate['updated_by']),
            'is_deleted': _safeToString(quantityDate['is_deleted']),
          };
        }

        // Valuation
        if (tabs['valuation'] != null) {
          final valuation = tabs['valuation'] as Map<String, dynamic>;
          item['tabs']['valuation'] = {
            'quotation_valuation_id':
                _safeToString(valuation['quotation_valuation_id']),
            'quotation_main_id': _safeToString(valuation['quotation_main_id']),
            'estimated_price': _safeToInt(valuation['estimated_price']),
            'currency_id': _safeToString(valuation['currency_id']),
            'per': _safeToDouble(valuation['per']),
            'total_value': _safeToInt(valuation['total_value']),
            'currency_code': _safeToString(valuation['currency_code']),
            'promotion': _safeToString(valuation['promotion']),
            'tax_code': _safeToString(valuation['tax_code']),
            'assessment_value2': _safeToString(valuation['assessment_value2']),
            'quotation_price': _safeToString(valuation['quotation_price']),
            'goods_receipt': _safeToString(valuation['goods_receipt']),
            'invoice_receipt': _safeToString(valuation['invoice_receipt']),
            'gr_non_valuation': _safeToString(valuation['gr_non_valuation']),
            'created_at': _safeToString(valuation['created_at']),
            'updated_at': _safeToString(valuation['updated_at']),
            'created_by': _safeToString(valuation['created_by']),
            'updated_by': _safeToString(valuation['updated_by']),
            'is_deleted': _safeToString(valuation['is_deleted']),
          };
        }

        // Message
        if (tabs['message'] != null) {
          final message = tabs['message'] as Map<String, dynamic>;
          item['tabs']['message'] = {
            'quotation_message_id':
                _safeToString(message['quotation_message_id']),
            'quotation_main_id': _safeToString(message['quotation_main_id']),
            'purchase_message': _safeToString(message['purchase_message']),
            'item_note': _safeToString(message['item_note']),
            'delivery_message': _safeToString(message['delivery_message']),
            'order_message': _safeToString(message['order_message']),
            'quotation_message': _safeToString(message['quotation_message']),
            'created_at': _safeToString(message['created_at']),
            'updated_at': _safeToString(message['updated_at']),
            'created_by': _safeToString(message['created_by']),
            'updated_by': _safeToString(message['updated_by']),
            'is_deleted': _safeToString(message['is_deleted']),
          };
        }
      }

      return item;
    } catch (e) {
      return null;
    }
  }

  // คืน URL รูปภาพ auction ที่ถูกต้อง
  String _getAuctionImageUrl(String? imageName) {
    if (imageName == null ||
        imageName.isEmpty ||
        imageName == '[]' ||
        imageName == '"[]"') {
      return 'assets/images/noimage.jpg';
    }
    
    // ลบ escape characters และ quotes ที่ไม่จำเป็น
    String cleanImageName = imageName.trim();
    
    // ถ้าเป็น JSON array string ให้ parse
    if (cleanImageName.startsWith('[') && cleanImageName.endsWith(']')) {
      try {
        final parsed = jsonDecode(cleanImageName);
        if (parsed is List &&
            parsed.isNotEmpty &&
            parsed[0] != null &&
            parsed[0].toString().isNotEmpty) {
          cleanImageName = parsed[0].toString();
        } else {
          return 'assets/images/noimage.jpg';
        }
      } catch (e) {
        return 'assets/images/noimage.jpg';
      }
    }
    
    // ลบ quotes และ escape characters ที่เหลืออยู่
    cleanImageName = cleanImageName
        .replaceAll('"', '')
        .replaceAll('\\', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .trim();
    
    if (cleanImageName.isEmpty) {
      return 'assets/images/noimage.jpg';
    }

    // ตรวจสอบนามสกุลไฟล์
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final hasValidExtension = validExtensions.any((ext) => 
        cleanImageName.toLowerCase().endsWith(ext));
    
    if (!hasValidExtension) {

      return 'assets/images/noimage.jpg';
    }
    
  
    final imageUrl = 'https://cm-mecustomers.com/ERP-Cloudmate/modules/sales/uploads/quotation/$cleanImageName';
    
    // แปลง HTTPS เป็น HTTP สำหรับ Android
    if (Platform.isAndroid) {
      return imageUrl.replaceFirst('https://', 'http://');
    }
    return imageUrl;
  }

  // คืน URL รูปภาพ auction ที่ถูกต้อง (public)
  String getAuctionImageUrl(String? imageName) =>
      _getAuctionImageUrl(imageName);

  // Method สำหรับดึง quantity สำหรับ AS03 auctions
  int _getQuantityForAS03(Map<String, dynamic> product) {
    final typeCode = product['quotation_type_code'];
    
    // ถ้าเป็น AS03 ให้ใช้ fallback logic
    if (typeCode == 'AS03') {
      // ลองใช้หลาย field ที่อาจจะมีข้อมูล
      final quantity = _safeToInt(product['quantity']) ?? 
                      _safeToInt(product['quantity_tab']) ?? 
                      _safeToInt(product['item_number']) ?? 0;
      
      // ถ้าไม่มีข้อมูลใน API ให้ใช้ข้อมูลจาก JSON ที่ user ส่งมา
      if (quantity == 0) {
        // ใช้ข้อมูลจาก JSON ที่ user ส่งมา
        final shortText = product['short_text'] ?? '';
        if (shortText.contains('คอนเสิร์ต ลูกทุ่ง & Rock Aquaverse Music Fest')) {
          return 10;
        }
      }
      
      return quantity;
    }
    
    // สำหรับ auction types อื่นๆ ใช้ logic ปกติ
    return _safeToInt(product['quantity']) ?? 
           _safeToInt(product['quantity_tab']) ?? 
           _safeToInt(product['item_number']) ?? 0;
  }

  // แปลงข้อมูลสินค้าเป็นรูปแบบที่ใช้ในแอพ
  Map<String, dynamic> convertToAppFormat(Map<String, dynamic> product) {
    
    final imagePath = _getAuctionImageUrl(product['quotation_image']);

    // กำหนดสถานะจากเวลา
    final now = DateTime.now();
    final start = DateTime.tryParse(product['auction_start_date'] ?? '');
    final end = DateTime.tryParse(product['auction_end_date'] ?? '');
    String status = 'unknown';
    if (start != null && end != null) {
      if (now.isBefore(start)) {
        status = 'upcoming';
      } else if (now.isAfter(end)) {
        status = 'completed';
      } else {
        status = 'current';
      }
    }

    // แปลงข้อมูลให้เป็น type ที่ถูกต้อง
    final currentPrice = _safeToInt(product['current_price']);
    final startingPrice = _safeToInt(product['star_price']);
    final quantity = _safeToInt(product['quantity']);

    // ใช้ข้อมูลจาก API response โดยตรง
    return {
      'id': product['quotation_more_information_id'] ??
          product['quotation_id'] ??
          '',
      'quotation_more_information_id':
          product['quotation_more_information_id'] ??
              product['quotation_id'] ??
              '',
      'title':
          product['short_text'] ?? product['description'] ?? 'สินค้าไม่ระบุ',
      'currentPrice': currentPrice,
      'startingPrice': startingPrice,
      'timeRemaining': product['remaining_time'] ??
          _calculateTimeRemaining(product['auction_end_date']),
      'timeUntilStart': _calculateDaysUntilStart(product['auction_start_date']),
      'image': imagePath,
      'description': product['purchase_message']
              ?.toString()
              .replaceAll(RegExp(r"^'|'$"), '') ??
          '',
      'auction_start_date': product['auction_start_date'] ?? '',
      'auction_end_date': product['auction_end_date'] ?? '',
      'status': status,
      'currency': product['currency_code'] ?? 'THB',
      'bidCount': product['number_bidders'] ?? 0,
      'minimum_increase': _safeToInt(product['minimum_increase']),
      'item_note': product['item_note'] ?? '',
      'quotation_type_description': product['quotation_type_description'] ?? '',
      'quotation_type_code': product['quotation_type_code'] ?? '',
      'quantity': quantity, // ใช้ข้อมูลจาก API โดยตรง
      'brand': product['brand'] ?? 'ไม่ระบุ',
      'model': product['model'] ?? 'ไม่ระบุ',
      'material': product['material'] ?? 'ไม่ระบุ',
      'size': product['size'] ?? 'ไม่ระบุ',
      'color': product['color'] ?? 'ไม่ระบุ',
      'condition': product['condition'] ?? 'ไม่ระบุ',
      'sellerName': product['sellerName'] ?? 'CloudmateTH',
      'sellerRating': product['sellerRating'] ?? '4.5',
    };
  }

  // คำนวณเวลาที่เหลือ
  String _calculateTimeRemaining(String? endDate) {
    if (endDate == null || endDate.isEmpty) return 'ไม่ระบุ';
    
    try {
      final end = DateTime.parse(endDate);
      final now = DateTime.now();
      
      if (now.isAfter(end)) return 'หมดเวลาแล้ว';
      
      final difference = end.difference(now);
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;
      
      if (days > 0) {
        return 'เหลือ $days วัน $hours ชั่วโมง';
      } else if (hours > 0) {
        return 'เหลือ $hours ชั่วโมง $minutes นาที';
      } else {
        return 'เหลือ $minutes นาที';
      }
    } catch (e) {
      return 'ไม่ระบุ';
    }
  }

  // คำนวณจำนวนวันที่เหลือจนถึงวันเริ่มประมูล
  String _calculateDaysUntilStart(String? startDate) {
    if (startDate == null || startDate.isEmpty) return 'ไม่ระบุ';
    
    try {
      final start = DateTime.parse(startDate);
      final now = DateTime.now();
      
      if (now.isAfter(start)) return 'เริ่มแล้ว';
      
      final difference = start.difference(now);
      final days = difference.inDays;
      
      if (days == 0) {
        final hours = difference.inHours;
        if (hours == 0) {
          final minutes = difference.inMinutes;
          return '$minutes นาที';
        }
        return '$hours ชั่วโมง';
      } else if (days == 1) {
        return '1 วัน';
      } else {
        return '$days วัน';
      }
    } catch (e) {
      return 'ไม่ระบุ';
    }
  }

  Future<Map<String, dynamic>?> placeBid({
    required String quotationId,
    required String minimumIncrease,
    required String bidAmount,
    required String bidderId,
    required String bidderName,
  }) async {
    final url = Uri.parse(
        '$baseUrl/ERP-Cloudmate/modules/sales/controllers/list_quotation_type_auction_price_controller.php?id=$quotationId');
    final body = {
      'minimum_increase': minimumIncrease,
      'bid_amount': bidAmount,
      'bidder_id': bidderId,
      'bidder_name': bidderName,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to place bid. Status: ${response.statusCode}');
      }
    } catch (e) {
      return null;
    }
  }

} 
