// features/auth/providers/auth_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/utils/storage_service.dart';

// የ Auth State ደረጃዎች
class AuthState {
  final bool isLoading;
  final String? error;
  final String? role;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.error,
    this.role,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? role,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      role: role ?? this.role,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth Notifier Class
class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();
  final SocketService _socketService;

  AuthNotifier(this._socketService) : super(AuthState());

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.login}',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        final user = data['user'];

        // 1. መረጃውን በ Secure Storage ማስቀመጥ
        await _storage.saveAuthData(
          token: token,
          userId: user['id'],
          role: user['role'],
          name: user['full_name'],
        );

        // 2. Real-time Socket ማስጀመር እና ወደ ክፍል ማስገባት
        _socketService.initSocket(
          role: user['role'],
          userId: user['id'],
        );

        // 3. State ማስተካከል
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          role: user['role'],
        );
        return true;
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? 'ሎግኢን ማድረግ አልተቻለም!';
      state = state.copyWith(isLoading: false, error: errorMsg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'የኔትወርክ ስህተት ተፈጥሯል!');
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _socketService.disconnect();
    state = AuthState();
  }
}

// Providers
final socketServiceProvider = Provider((ref) => SocketService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return AuthNotifier(socketService);
});
