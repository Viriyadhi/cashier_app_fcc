import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final Dio _dio = ApiClient.instance.dio;

  Future<String> login({required String name, required String password}) async {
    final response = await _dio.post(
      '/db/login_page/log_in',
      data: {'name': name, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return response.data.toString();
  }

  Future<void> logout() async {
    final response = await _dio.get('/db/login_page/log_out');
    if (response.data.toString() == 'err from sql') {
      throw Exception('Server returned error');
    }
  }
}
