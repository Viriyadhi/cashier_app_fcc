import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';

class StockItem {
  StockItem({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.price,
    required this.imageBase64,
    this.type,
  });

  final int id;
  final String name;
  final int currentStock;
  final int price;
  final String imageBase64;
  final String? type;

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      currentStock: _toInt(json['currentStock']),
      price: _toInt(json['price']),
      imageBase64: json['image']?.toString() ?? '',
      type: json['type']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class StockService {
  StockService._();

  static final StockService instance = StockService._();
  final Dio _dio = ApiClient.instance.dio;

  bool _isActiveItem(Map<String, dynamic> json) {
    final expiry = json['expiry'];
    if (expiry == null) return true;
    if (expiry is String && expiry.trim().isEmpty) return true;
    return false;
  }

  List<StockItem> _mapItems(List<dynamic> data) {
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where(_isActiveItem)
        .map(StockItem.fromJson)
        .toList();
  }

  Future<List<StockItem>> fetchItemList() async {
    final response = await _dio.get('/db/stock_page/fetch_item_list');
    final data = response.data;

    if (data is String) {
      if (data == 'err from sql') {
        throw Exception('Server returned error');
      }
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return _mapItems(decoded);
      }
    }

    if (data is List) {
      return _mapItems(data);
    }

    throw Exception('Unexpected response');
  }

  Future<String> createItem({
    required String name,
    required int stock,
    required int price,
    String? imagePath,
    String? type,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'stock': stock.toString(),
      'price': price.toString(),
    });

    if (type != null && type.isNotEmpty) {
      form.fields.add(MapEntry('type', type));
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      form.files.add(
        MapEntry(
          'icon',
          await MultipartFile.fromFile(imagePath),
        ),
      );
    }

    final response = await _dio.post(
      '/db/stock_page/new_item',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    final body = response.data.toString();
    if (body == 'err from sql') {
      throw Exception('Server returned error');
    }
    return body;
  }

  Future<String> updateItem({
    required int itemId,
    required String name,
    required int stock,
    required int price,
    String? imagePath,
    String? type,
  }) async {
    final form = FormData.fromMap({
      'item_id': itemId.toString(),
      'name': name,
      'stock': stock.toString(),
      'price': price.toString(),
    });

    if (type != null && type.isNotEmpty) {
      form.fields.add(MapEntry('type', type));
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      form.files.add(
        MapEntry(
          'icon',
          await MultipartFile.fromFile(imagePath),
        ),
      );
    }

    final response = await _dio.post(
      '/db/stock_page/update_item',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    final body = response.data.toString();
    if (body == 'err from sql') {
      throw Exception('Server returned error');
    }
    return body;
  }

  Future<String> deleteItems(List<int> itemIds) async {
    final response = await _dio.post(
      '/db/stock_page/delete_item',
      data: {
        'item_id_array': jsonEncode(itemIds),
      },
    );

    final body = response.data.toString();
    if (body == 'err from sql') {
      throw Exception('Server returned error');
    }
    return body;
  }
}
