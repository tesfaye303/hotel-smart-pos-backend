import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../utils/offline_sync_service.dart';

class OrderService {
  final Dio dio = Dio();
  final OfflineSyncService offlineSyncService = OfflineSyncService();

  // ትዕዛዝ ወደ ሰርቨር የመላክ እና Offline ከሆነ Local የማስቀመጥ Function
  Future<bool> sendOrder(Map<String, dynamic> orderData) async {
    try {
      // 1. በመጀመሪያ ወደ Backend ለመላክ መሞከር
      final response = await dio.post(ApiConstants.orders, data: orderData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // 2. ኔትወርክ ከሌለ ወይም ከተቋረጠ በአካባቢው (Hive DB) እንዲቀመጥ ማድረግ
      await offlineSyncService.saveOrderOffline(orderData);
      return false; // Offline መሆኑን ለ UI ለማሳወቅ
    }
  }
}