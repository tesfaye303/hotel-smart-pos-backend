class ApiConstants {
  // ለ Android Emulator: 'http://10.0.2.2:5000/api/v1'
  // ለትክክለኛ ስልክ (Wi-Fi): 'http://192.168.x.x:5000/api/v1'
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';
  static const String socketUrl = 'http://10.0.2.2:5000';

  static const String login = '/auth/login';
  static const String tables = '/tables';
  static const String menu = '/menu';
  static const String orders = '/orders';
  static const String payments = '/payments';
  static const String shifts = '/shifts';
}
