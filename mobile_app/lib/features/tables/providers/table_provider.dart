// features/tables/providers/table_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class DiningTable {
  final int id;
  final String tableNumber;
  final int capacity;
  final String status; // 'AVAILABLE', 'OCCUPIED', 'RESERVED'

  DiningTable({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.status,
  });

  factory DiningTable.fromJson(Map<String, dynamic> json) {
    return DiningTable(
      id: json['id'],
      tableNumber: json['table_number'],
      capacity: json['capacity'] ?? 4,
      status: json['status'] ?? 'AVAILABLE',
    );
  }
}

final apiClientProvider = Provider((ref) => ApiClient());

final tablesProvider = FutureProvider<List<DiningTable>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.dio.get(ApiConstants.tables);
  final List data = response.data;
  return data.map((json) => DiningTable.fromJson(json)).toList();
});
