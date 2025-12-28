import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';

class SummaryRecord {
  SummaryRecord({
    required this.time,
    required this.itemId,
    required this.name,
    required this.count,
    required this.price,
  });

  final DateTime time;
  final int itemId;
  final String name;
  final int count;
  final int price;

  factory SummaryRecord.fromJson(Map<String, dynamic> json) {
    return SummaryRecord(
      time: DateTime.parse(json['time']?.toString() ?? ''),
      itemId: _toInt(json['item_id']),
      name: json['name']?.toString() ?? '',
      count: _toInt(json['count']),
      price: _toInt(json['price']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class SummaryService {
  SummaryService._();

  static final SummaryService instance = SummaryService._();
  final Dio _dio = ApiClient.instance.dio;

  Future<List<SummaryRecord>> fetchSummary() async {
    final response = await _dio.get('/db/summary_page/high_level');
    final data = response.data;

    if (data is String) {
      if (data == 'err from sql') {
        throw Exception('Server returned error');
      }
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => SummaryRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => SummaryRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    throw Exception('Unexpected response');
  }
}
