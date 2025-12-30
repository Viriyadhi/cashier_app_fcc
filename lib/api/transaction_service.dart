import 'dart:convert';

import 'package:dio/dio.dart';
import 'api_client.dart';

class TransactionService {
  TransactionService._();

  static final TransactionService instance = TransactionService._();
  final Dio _dio = ApiClient.instance.dio;

  Future<void> createTransaction(Map<String, int> items) async {
    final response = await _dio.post(
      '/db/transaction_page/new_transaction',
      data: {'data': jsonEncode(items)},
    );

    final body = response.data;
    if (body is String && body == 'err from sql') {
      throw Exception('Server returned error');
    }
  }
}
