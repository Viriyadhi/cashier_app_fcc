import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';

class TransactionRecord {
  TransactionRecord({
    required this.time,
    required this.itemId,
    required this.name,
    required this.count,
    required this.price,
    required this.rank,
  });

  final DateTime time;
  final int itemId;
  final String name;
  final int count;
  final int price;
  final int rank;

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      time: DateTime.parse(json['time']?.toString() ?? ''),
      itemId: _toInt(json['item_id']),
      name: json['name']?.toString() ?? '',
      count: _toInt(json['count']),
      price: _toInt(json['price']),
      rank: _toInt(json['rank']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class TransactionService {
  TransactionService._();

  static final TransactionService instance = TransactionService._();
  final Dio _dio = ApiClient.instance.dio;

  Future<List<TransactionRecord>> fetchTransactionHistory() async {
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
            .map(
              (e) => TransactionRecord.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    }

    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => TransactionRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    throw Exception('Unexpected response');
  }
}
