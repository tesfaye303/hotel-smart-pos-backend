// core/network/api_client.dart
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../utils/storage_service.dart';

class ApiClient {
  final Dio dio = Dio();
  final StorageService _storage = StorageService();

  ApiClient() {
    dio.options.baseUrl = ApiConstants.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // 401 Unauthorized ከሆነ መግቢያ ገጽ የመመለስ ሎጂክ እዚህ መጨመር ይቻላል
          return handler.next(error);
        },
      ),
    );
  }
}
