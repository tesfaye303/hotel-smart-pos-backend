// features/payments/providers/payment_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../tables/providers/table_provider.dart';

class UnpaidOrder {
  final int id;
  final String tableNumber;
  final String waitressName;
  final double totalAmount;
  final DateTime createdAt;
  final List<Map<String, dynamic>> items;

  UnpaidOrder({
    required this.id,
    required this.tableNumber,
    required this.waitressName,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  factory UnpaidOrder.fromJson(Map<String, dynamic> json) {
    return UnpaidOrder(
      id: json['id'],
      tableNumber: json['table_number']?.toString() ?? 'N/A',
      waitressName: json['waitress_name'] ?? 'አስተናጋጅ',
      totalAmount: double.parse(json['total_amount'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
    );
  }
}

class ShiftSummary {
  final double totalCash;
  final double totalTelebirr;
  final double totalSales;
  final int totalOrdersCount;

  ShiftSummary({
    required this.totalCash,
    required this.totalTelebirr,
    required this.totalSales,
    required this.totalOrdersCount,
  });

  factory ShiftSummary.fromJson(Map<String, dynamic> json) {
    return ShiftSummary(
      totalCash: double.parse((json['total_cash'] ?? 0).toString()),
      totalTelebirr: double.parse((json['total_telebirr'] ?? 0).toString()),
      totalSales: double.parse((json['total_sales'] ?? 0).toString()),
      totalOrdersCount: json['total_orders_count'] ?? 0,
    );
  }
}

class PaymentNotifier extends StateNotifier<AsyncValue<List<UnpaidOrder>>> {
  final ApiClient _apiClient;

  PaymentNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchUnpaidOrders();
  }

  // ያልተከፈሉ ሂሳቦችን ከ Backend ማምጣት
  Future<void> fetchUnpaidOrders() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.payments}/unpaid');
      final List data = response.data;
      final orders = data.map((e) => UnpaidOrder.fromJson(e)).toList();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ክፍያ መፈጸም
  Future<bool> processPayment({
    required int orderId,
    required String paymentMethod, // 'CASH', 'TELEBIRR', 'CARD'
    required double amountPaid,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.payments,
        data: {
          'order_id': orderId,
          'payment_method': paymentMethod,
          'amount_paid': amountPaid,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchUnpaidOrders();
        return true;
      }
    } catch (e) {
      print('Payment error: $e');
    }
    return false;
  }

  // የሺፍት መረጃ ማምጣት
  Future<ShiftSummary?> getShiftSummary() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.shifts}/current-summary');
      return ShiftSummary.fromJson(response.data);
    } catch (e) {
      print('Shift summary error: $e');
      return null;
    }
  }

  // ሺፍት መዝጋት
  Future<bool> closeShift() async {
    try {
      final response = await _apiClient.dio.post('${ApiConstants.shifts}/close');
      return response.statusCode == 200;
    } catch (e) {
      print('Close shift error: $e');
      return false;
    }
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<List<UnpaidOrder>>>((ref) {
  final client = ref.watch(apiClientProvider);
  return PaymentNotifier(client);
});
