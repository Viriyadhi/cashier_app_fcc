import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();
  static const String baseUrl = 'http://10.0.2.2:3000';

  final CookieJar _cookieJar = CookieJar();
  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    ),
  )..interceptors.add(CookieManager(_cookieJar));
}
