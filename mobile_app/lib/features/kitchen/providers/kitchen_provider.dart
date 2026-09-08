// features/kitchen/providers/kitchen_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';

class KitchenOrderItem {
  final int id;
  final String menuName;
  final int quantity;

  KitchenOrderItem({
    required this.id,
    required this.menuName,
    required this.quantity,
  });

  factory KitchenOrderItem.fromJson(Map<String, dynamic> json) {
    return KitchenOrderItem(
      id: json['id'],
      menuName: json['menu_name'] ?? json['name'] ?? 'ምግብ',
      quantity: json['quantity'],
    );
  }
}

class KitchenOrder {
  final int id;
  final String tableNumber;
  final String waitressName;
  final String status; // 'PENDING', 'IN_PREPARATION', 'READY'
  final String? notes;
  final DateTime createdAt;
  final List<KitchenOrderItem> items;

  KitchenOrder({
    required this.id,
    required this.tableNumber,
    required this.waitressName,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    var itemsList = (json['items'] as List? ?? [])
        .map((i) => KitchenOrderItem.fromJson(i))
        .toList();

    return KitchenOrder(
      id: json['id'],
      tableNumber: json['table_number']?.toString() ?? 'N/A',
      waitressName: json['waitress_name'] ?? 'አስተናጋጅ',
      status: json['status'] ?? 'PENDING',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      items: itemsList,
    );
  }
}

class KitchenNotifier extends StateNotifier<AsyncValue<List<KitchenOrder>>> {
  final ApiClient _apiClient;
  final SocketService _socketService;

  KitchenNotifier(this._apiClient, this._socketService)
      : super(const AsyncValue.loading()) {
    fetchActiveOrders();
    _initSocketListener();
  }

  // ያልተጠናቀቁ ትዕዛዞችን ከ Backend ማምጣት
  Future<void> fetchActiveOrders() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.orders}/active');
      final List data = response.data;
      final orders = data.map((json) => KitchenOrder.fromJson(json)).toList();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Socket listener ለአዳዲስ ትዕዛዞች
  void _initSocketListener() {
    _socketService.listenNewOrders((data) {
      print('🍳 በ Real-time አዲስ ትዕዛዝ ደረሰ: $data');
      // አዲስ ትዕዛዝ ሲመጣ ዳታውን እንደገና አዲስ ማድረግ
      fetchActiveOrders();
    });
  }

  // የትዕዛዝ ሁኔታን መቀየር (PENDING -> IN_PREPARATION -> READY)
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.orders}/$orderId/status',
        data: {'status': newStatus},
      );

      if (response.statusCode == 200) {
        // የነበረውን ስቴት በቦታው ማዘመን
        await fetchActiveOrders();
        return true;
      }
    } catch (e) {
      print('Status update error: $e');
    }
    return false;
  }
}

final kitchenProvider =
    StateNotifierProvider<KitchenNotifier, AsyncValue<List<KitchenOrder>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final socketService = ref.watch(socketServiceProvider);
  return KitchenNotifier(apiClient, socketService);
});
