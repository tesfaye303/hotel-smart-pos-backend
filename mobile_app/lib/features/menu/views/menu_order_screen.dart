// features/menu/views/menu_order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../tables/providers/table_provider.dart';
import '../providers/cart_provider.dart';

class MenuOrderScreen extends ConsumerStatefulWidget {
  final DiningTable table;
  const MenuOrderScreen({Key? key, required this.table}) : super(key: key);

  @override
  ConsumerState<MenuOrderScreen> createState() => _MenuOrderScreenState();
}

class _MenuOrderScreenState extends ConsumerState<MenuOrderScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  void _submitOrder() async {
    setState(() => _isSubmitting = true);
    final success = await ref.read(cartProvider.notifier).sendOrder(
          widget.table.id,
          _notesController.text,
        );
    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ref.refresh(tablesProvider); // የጠረጴዛዎች ሁኔታ አዲስ እንዲሆን
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ትዕዛዙ በተካ ሁኔታ ለወጥ ቤት ተልኳል!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuItemsProvider);
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('ጠረጴዛ ${widget.table.tableNumber} - ትዕዛዝ መዝግብ',
            style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: menuAsync.when(
        loading: () => const Center(child: SpinKitFadingCircle(color: Colors.deepOrange)),
        error: (err, stack) => Center(child: Text('ምግቦችን ማምጣት አልተቻለም: $err')),
        data: (menuItems) {
          return Column(
            children: [
              // የምግብ ዝርዝር
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final cartItem = cart.firstWhere(
                      (c) => c.item.id == item.id,
                      orElse: () => CartItem(item: item, quantity: 0),
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(item.name, style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.price.toStringAsFixed(2)} ብር', style: const TextStyle(color: Colors.deepOrange)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (cartItem.quantity > 0) ...[
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => cartNotifier.removeItem(item),
                              ),
                              Text('${cartItem.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onPressed: () => cartNotifier.addItem(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // የካርት ማጠቃለያ እና ትዕዛዝ መላኪያ Bottom Bar
              if (cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ጠቅላላ ሂሳብ:', style: GoogleFonts.notoSansEthiopic(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${cartNotifier.totalPrice.toStringAsFixed(2)} ብር',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isSubmitting
                              ? const SpinKitThreeBounce(color: Colors.white, size: 20)
                              : Text('ትዕዛዝ ወደ ወጥ ቤት ላክ', style: GoogleFonts.notoSansEthiopic(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
