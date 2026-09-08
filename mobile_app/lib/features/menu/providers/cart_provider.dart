// features/menu/providers/cart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../tables/providers/table_provider.dart';

class MenuItemModel {
  final int id;
  final String name;
  final double price;
  final String category;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      name: json['name'],
      price: double.parse(json['price'].toString()),
      category: json['category'] ?? 'ምግብ',
    );
  }
}

class CartItem {
  final MenuItemModel item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  final ApiClient _apiClient;

  CartNotifier(this._apiClient) : super([]);

  // ምግብ ወደ ካርት መጨመር
  void addItem(MenuItemModel item) {
    final existingIndex = state.indexWhere((element) => element.item.id == item.id);
    if (existingIndex >= 0) {
      state[existingIndex].quantity++;
      state = [...state];
    } else {
      state = [...state, CartItem(item: item)];
    }
  }

  // ምግብ ከካርት መቀነስ
  void removeItem(MenuItemModel item) {
    final existingIndex = state.indexWhere((element) => element.item.id == item.id);
    if (existingIndex >= 0) {
      if (state[existingIndex].quantity > 1) {
        state[existingIndex].quantity--;
        state = [...state];
      } else {
        state = state.where((element) => element.item.id != item.id).toList();
      }
    }
  }

  // አጠቃላይ ዋጋ ማሰያ
  double get totalPrice {
    return state.fold(0, (sum, item) => sum + (item.item.price * item.quantity));
  }

  // ካርቱን ባዶ ማድረግ
  void clear() {
    state = [];
  }

  // ትዕዛዙን ወደ Backend መላክ (Submit Order)
  Future<bool> sendOrder(int tableId, String? notes) async {
    if (state.isEmpty) return false;

    final orderItemsPayload = state
        .map((e) => {
              'menu_item_id': e.item.id,
              'quantity': e.quantity,
              'unit_price': e.item.price,
            })
        .toList();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.orders,
        data: {
          'table_id': tableId,
          'items': orderItemsPayload,
          'notes': notes ?? '',
        },
      );

      if (response.statusCode == 201) {
        clear();
        return true;
      }
    } catch (e) {
      print('Order Error: $e');
    }
    return false;
  }
}

final menuItemsProvider = FutureProvider<List<MenuItemModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.dio.get(ApiConstants.menu);
  final List data = response.data;
  return data.map((json) => MenuItemModel.fromJson(json)).toList();
});

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final client = ref.watch(apiClientProvider);
  return CartNotifier(client);
});
