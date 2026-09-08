import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; // 1. package0 የነበረው ወደ package: ተስተካክሏል
import 'package:firebase_core/firebase_core.dart';
import 'core/utils/offline_sync_service.dart';
import 'core/services/fcm_service.dart';
import 'features/auth/views/login_screen.dart';
import 'features/tables/views/tables_screen.dart';
import 'features/kitchen/views/kitchen_kds_screen.dart';
import 'features/payments/views/cashier_dashboard_screen.dart';

void main() async {
  // 2. Flutter Widgets ማረጋገጥ
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Firebase እና Push Notifications ማስነሳት
  await Firebase.initializeApp();
  final fcmService = FCMService();
  await fcmService.initNotifications();

  // 4. Hive Local DB እና የ Wi-Fi Sync ማስነሳት
  final offlineSyncService = OfflineSyncService();
  await offlineSyncService.initHive();

  runApp(
    const ProviderScope(
      child: POSApplication(),
    ),
  );
}

class POSApplication extends StatelessWidget {
  const POSApplication({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant POS System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        textTheme: GoogleFonts.notoSansEthiopicTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/waitress-dashboard': (context) => const TablesScreen(),
        '/kitchen-kds': (context) => const KitchenKDSScreen(),
        '/cashier-dashboard': (context) => const CashierDashboardScreen(),
      },
    );
  }
}