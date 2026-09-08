// features/auth/views/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
          );

      if (success && mounted) {
        final role = ref.read(authProvider).role;
        _navigateToRoleDashboard(role);
      }
    }
  }

  // እንደ ተጠቃሚው Role ወደ ተለያዩ ገጾች መምሪያ
  void _navigateToRoleDashboard(String? role) {
    switch (role) {
      case 'WAITRESS':
        // Navigator.pushReplacementNamed(context, '/waitress-dashboard');
        _showSuccessSnack('እንኳን ደህና መጡ! (Waitress Dashboard)');
        break;
      case 'KITCHEN':
        // Navigator.pushReplacementNamed(context, '/kitchen-kds');
        _showSuccessSnack('እንኳን ደህና መጡ! (Kitchen KDS)');
        break;
      case 'CASHIER':
        // Navigator.pushReplacementNamed(context, '/cashier-dashboard');
        _showSuccessSnack('እንኳን ደህና መጡ! (Cashier Counter)');
        break;
      default:
        _showSuccessSnack('እንኳን ደህና መጡ!');
    }
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.restaurant_menu, size: 64, color: Colors.deepOrange),
                  const SizedBox(height: 16),
                  Text(
                    'POS System',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  Text(
                    'እባክዎን መለያ ቁጥርዎን ያስገቡ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansEthiopic(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  // Error message display
                  if (authState.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        authState.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'የተጠቃሚ ስም (Username)',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val!.isEmpty ? 'እባክዎን የተጠቃሚ ስም ያስገቡ' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'የምስጢር ቃል (Password)',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val!.isEmpty ? 'እባክዎን የምስጢር ቃል ያስገቡ' : null,
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: authState.isLoading
                        ? const SpinKitThreeBounce(color: Colors.white, size: 24)
                        : Text(
                            'ግልግሎት ጀምር (Login)',
                            style: GoogleFonts.notoSansEthiopic(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
