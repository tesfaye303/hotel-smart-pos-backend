// features/tables/views/tables_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/table_provider.dart';
import '../../menu/views/menu_order_screen.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({Key? key}) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'OCCUPIED':
        return Colors.redAccent;
      case 'RESERVED':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  String _getStatusAmharic(String status) {
    switch (status) {
      case 'AVAILABLE':
        return 'ነፃ';
      case 'OCCUPIED':
        return 'የተያዘ';
      case 'RESERVED':
        return 'የተያዘበት';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('የጠረጴዛዎች ሁኔታ', style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(tablesProvider),
          )
        ],
      ),
      body: tablesAsync.when(
        loading: () => const Center(child: SpinKitFadingCircle(color: Colors.deepOrange)),
        error: (err, stack) => Center(child: Text('ስህተት ተፈጥሯል: $err')),
        data: (tables) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              final statusColor = _getStatusColor(table.status);

              return InkWell(
                onTap: () {
                  // ወደ አዲስ ትዕዛዝ ማያ መሄድ
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuOrderScreen(table: table),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_restaurant, size: 48, color: statusColor),
                      const SizedBox(height: 8),
                      Text(
                        'ጠረጴዛ ${table.tableNumber}',
                        style: GoogleFonts.notoSansEthiopic(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusAmharic(table.status),
                          style: GoogleFonts.notoSansEthiopic(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
