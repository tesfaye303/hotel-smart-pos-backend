// features/kitchen/views/kitchen_kds_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/kitchen_provider.dart';

class KitchenKDSScreen extends ConsumerWidget {
  const KitchenKDSScreen({Key? key}) : super(key: key);

  Color _getStatusHeaderColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange.shade700;
      case 'IN_PREPARATION':
        return Colors.blue.shade700;
      case 'READY':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(kitchenProvider);
    final kitchenNotifier = ref.read(kitchenProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), // ለወጥ ቤት ሞኒተር ምቹ የሆነ Dark Theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D44),
        title: Text(
          '👨🍳 Kitchen Display System (KDS)',
          style: GoogleFonts.notoSansEthiopic(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => kitchenNotifier.fetchActiveOrders(),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: SpinKitFadingCircle(color: Colors.amber, size: 50),
        ),
        error: (err, stack) => Center(
          child: Text('ትዕዛዞችን ማምጣት አልተቻለም: $err',
              style: const TextStyle(color: Colors.white)),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.greenAccent),
                  const SizedBox(height: 16),
                  Text(
                    'ምንም የሚሰራ ትዕዛዝ የለም!',
                    style: GoogleFonts.notoSansEthiopic(
                      color: Colors.white70,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              mainAxisExtent: 420,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final headerColor = _getStatusHeaderColor(order.status);
              final timeFormatted =
                  DateFormat('hh:mm a').format(order.createdAt);

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D44),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: headerColor, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: headerColor,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ጠረጴዛ ${order.tableNumber}',
                            style: GoogleFonts.notoSansEthiopic(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '#${order.id} | $timeFormatted',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Waitress Info & Notes
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(
                            order.waitressName,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),

                    if (order.notes != null && order.notes!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ማስታወሻ: ${order.notes}',
                          style: GoogleFonts.notoSansEthiopic(
                            color: Colors.amber,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const Divider(color: Colors.white12),

                    // Items List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: order.items.length,
                        itemBuilder: (context, iIndex) {
                          final item = order.items[iIndex];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.quantity}x',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.menuName,
                                    style: GoogleFonts.notoSansEthiopic(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Action Buttons ( Status Changer )
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: _buildActionButton(
                          context, order, kitchenNotifier),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, KitchenOrder order,
      KitchenNotifier notifier) {
    if (order.status == 'PENDING') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () =>
            notifier.updateOrderStatus(order.id, 'IN_PREPARATION'),
        child: Text(
          'ስራ ጀምር (Start Prep)',
          style: GoogleFonts.notoSansEthiopic(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    } else if (order.status == 'IN_PREPARATION') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => notifier.updateOrderStatus(order.id, 'READY'),
        child: Text(
          'ምግቡ አልቋል (Mark Ready)',
          style: GoogleFonts.notoSansEthiopic(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'ለአስተናጋጅ ተልኳል (Ready)',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansEthiopic(
              color: Colors.greenAccent, fontWeight: FontWeight.bold),
        ),
      );
    }
  }
}
