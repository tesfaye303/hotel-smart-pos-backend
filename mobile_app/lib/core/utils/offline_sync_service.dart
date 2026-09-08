import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/api_constants.dart';

class OfflineSyncService {
  static const String pendingOrdersBox = 'pending_orders_box';
  final Dio _dio = Dio();

  // 1. Hive ዳታቤዝ ማስነሳት
  Future<void> initHive() async {
    await Hive.initFlutter();
    await Hive.openBox(pendingOrdersBox);
    _listenToConnectivity();
  }

  // 2. ኔትወርክ ሲቋረጥ ትዕዛዝን Local Hive ውስጥ ማስቀመጥ
  Future<void> saveOrderOffline(Map<String, dynamic> orderData) async {
    final box = Hive.box(pendingOrdersBox);
    await box.add(orderData);
  }

  // 3. Wi-Fi መመለሱን መከታተልና አውቶማቲክ Sync ማድረግ
  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.wifi) || 
          results.contains(ConnectivityResult.mobile)) {
        syncPendingOrders();
      }
    });
  }

  // 4. የተቀመጡ ትዕዛዞችን ወደ backend ሰርቨር መላክ
  Future<void> syncPendingOrders() async {
    final box = Hive.box(pendingOrdersBox);
    if (box.isEmpty) return;

    final keysToDelete = <dynamic>[];

    for (var i = 0; i < box.length; i++) {
      final orderData = box.getAt(i);
      try {
        final response = await _dio.post(
          ApiConstants.orders,
          data: orderData,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          keysToDelete.add(box.keyAt(i));
        }
      } catch (e) {
        // ሰርቨሩ አሁንም አልተመለሰም፣ በቀጣይ ሙከራ ይላካል
        break;
      }
    }

    // የተላኩትን ከ Local DB ማጽዳት
    for (var key in keysToDelete) {
      await box.delete(key);
    }
  }
}