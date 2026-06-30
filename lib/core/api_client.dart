import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  late final Dio _dio;

  Dio get client => _dio;

  // Constructor
  ApiClient() {
    // Determine baseUrl dynamically based on platform:
    // Android emulator needs 10.0.2.2 to connect to host's localhost.
    // Real Android device uses the host machine's LAN IP (192.168.1.11).
    // iOS and web can connect directly to localhost.
    String baseUrl = 'http://localhost:8080';
    if (!kIsWeb && Platform.isAndroid) {
      // Pour l'émulateur Android (pointe vers le localhost de la machine hôte)
      baseUrl = 'http://10.0.2.2:8080';
      // Pour un appareil Android physique, décommentez la ligne ci-dessous avec votre IP locale :
      // baseUrl = 'http://192.168.1.11:8080';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Logging interceptor for debugging backend calls
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('--> ${options.method} ${options.uri}');
          debugPrint('Headers: ${options.headers}');
          if (options.data != null) {
            debugPrint('Body: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
          debugPrint('Response: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint('<-- ERROR: ${e.response?.statusCode} ${e.requestOptions.uri}');
          debugPrint('Message: ${e.message}');
          debugPrint('Response Data: ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
  }
}
