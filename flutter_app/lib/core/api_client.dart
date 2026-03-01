import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final apiClientProvider = Provider((ref) => ApiClient());

class ApiClient {
  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  // 🚀 Change this to your deployed Render/Railway URL when ready!
  static const String productionUrl = 'https://gram-rakkha-backend.onrender.com/api/v1';
  static const bool useProduction = false; // Switch to true for real user testing

  static String get baseUrl {
    if (useProduction) return productionUrl;
    
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (Platform.isAndroid) return 'http://192.168.10.115:8000/api/v1';
    return 'http://localhost:8000/api/v1';
  }

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // If token is not already set by a direct override, read from storage
        if (options.headers['Authorization'] == null) {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          // Automatic logout logic if token expires
          _storage.deleteAll();
        }
        return handler.next(e);
      },
    ));
  }

  Future<Response> post(String path, {dynamic data, String? token}) async {
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
    return await dio.post(path, data: data, options: options);
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, String? token}) async {
    final options = token != null
        ? Options(headers: {'Authorization': 'Bearer $token'})
        : null;
    return await dio.get(path,
        queryParameters: queryParameters, options: options);
  }
}
