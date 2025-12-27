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

  Future<List<StockItem>> fetchItemList() async {
    final response = await _dio.get('/db/stock_page/fetch_item_list');
    final data = response.data;

    if (data is String) {
      if (data == 'err from sql') {
        throw Exception('Server returned error');
      }
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => StockItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => StockItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    throw Exception('Unexpected response');
  }
}
