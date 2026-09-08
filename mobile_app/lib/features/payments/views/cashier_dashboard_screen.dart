// features/payments/views/cashier_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/payment_provider.dart';

class CashierDashboardScreen extends ConsumerWidget {
  const CashierDashboardScreen({Key? key}) : super(key: key);

  void _showPaymentModal(BuildContext context, UnpaidOrder order, WidgetRef ref) {
    String selectedMethod = 'CASH';
    final cashGivenController = TextEditingController(text: order.totalAmount.toString());
    double changeAmount = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final givenAmount = double.tryParse(cashGivenController.text) ?? 0.0;
            changeAmount = givenAmount > order.totalAmount ? givenAmount - order.totalAmount : 0.0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ክፍያ መፈጸሚያ - ጠረጴዛ ${order.tableNumber}',
                    style: GoogleFonts.notoSansEthiopic(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('መከፈል ያለበት አጠቃላይ ሂሳብ: ${order.totalAmount.toStringAsFixed(2)} ብር',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // የክፍያ መንገድ መምረጫ (Cash / Telebirr / Card)
                  Row(
                    children: [
                      _buildPaymentOption('CASH', '💵 በጥሬ ገንዘብ', selectedMethod, (val) {
                        setStateModal(() => selectedMethod = val);
                      }),
                      const SizedBox(width: 8),
                      _buildPaymentOption('TELEBIRR', '📱 ቴሌብር', selectedMethod, (val) {
                        setStateModal(() => selectedMethod = val);
                      }),
                    ],
                  ),

                  const SizedBox(height: 16),
                  if (selectedMethod == 'CASH') ...[
                    TextField(
                      controller: cashGivenController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'የተቀበሉት ገንዘብ መጠን (ብር)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setStateModal(() {}),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ተመላሽ (መልስ): ${changeAmount.toStringAsFixed(2)} ብር',
                      style: GoogleFonts.notoSansEthiopic(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],

                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final success = await ref.read(paymentProvider.notifier).processPayment(
                            orderId: order.id,
                            paymentMethod: selectedMethod,
                            amountPaid: givenAmount,
                          );

                      if (success && context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ክፍያው በተሳካ ሁኔታ ተፈጽሟል!'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    child: Text('ክፍያውን አጽድቅ (Confirm Payment)',
                        style: GoogleFonts.notoSansEthiopic(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOption(String value, String label, String groupValue, Function(String) onTap) {
    final isSelected = value == groupValue;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepOrange : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansEthiopic(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showShiftCloseDialog(BuildContext context, WidgetRef ref) async {
    final summary = await ref.read(paymentProvider.notifier).getShiftSummary();

    if (summary != null && context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('🔒 የሺፍት መዝጊያ ሪፖርት', style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('አጠቃላይ አስተናጋጅ አስተናጋጅ የተስተናገደበት:', '${summary.totalOrdersCount} ትዕዛዞች'),
                _buildSummaryRow('በጥሬ ገንዘብ (Cash):', '${summary.totalCash.toStringAsFixed(2)} ብር'),
                _buildSummaryRow('በቴሌብር (Telebirr):', '${summary.totalTelebirr.toStringAsFixed(2)} ብር'),
                const Divider(),
                _buildSummaryRow('ጠቅላላ የሺፍት ሽያጭ:', '${summary.totalSales.toStringAsFixed(2)} ብር', isBold: true),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ተመለስ'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  final closed = await ref.read(paymentProvider.notifier).closeShift();
                  if (closed && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ሺፍቱ በተካ ሁኔታ ተዘጋ!'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: Text('ሺፍት ዝጋ (End Shift)', style: GoogleFonts.notoSansEthiopic(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildSummaryRow(String label, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.notoSansEthiopic(fontSize: 13)),
          Text(val, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unpaidOrdersAsync = ref.watch(paymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('💳 ካሸር - የክፍያ መመዝገቢያ', style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold)),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            icon: const Icon(Icons.lock_clock),
            label: Text('ሺፍት ዝጋ', style: GoogleFonts.notoSansEthiopic()),
            onPressed: () => _showShiftCloseDialog(context, ref),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: unpaidOrdersAsync.when(
        loading: () => const Center(child: SpinKitFadingCircle(color: Colors.deepOrange)),
        error: (err, stack) => Center(child: Text('ማምጣት አልተቻለም: $err')),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Text('ምንም ያልተከፈለ ሂሳብ የለም!', style: GoogleFonts.notoSansEthiopic(fontSize: 18, color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepOrange,
                    child: Icon(Icons.receipt_long, color: Colors.white),
                  ),
                  title: Text(
                    'ጠረጴዛ ${order.tableNumber} (ትዕዛዝ #${order.id})',
                    style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text('አስተናጋጅ: ${order.waitressName} • ${order.items.length} ምግቦች'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${order.totalAmount.toStringAsFixed(2)} ብር',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      Text('ክፍያ ይቀበሉ ➔', style: GoogleFonts.notoSansEthiopic(fontSize: 12, color: Colors.blue)),
                    ],
                  ),
                  onTap: () => _showPaymentModal(context, order, ref),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
