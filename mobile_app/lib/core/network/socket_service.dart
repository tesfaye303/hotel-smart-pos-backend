import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class SocketService {
  late IO.Socket _socket;

  void initSocket({required String role, required int userId}) {
    _socket = IO.io(
      ApiConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      print('🔌 Socket ተገናኝቷል: ${_socket.id}');
      // ተጠቃሚውን ወደ ስራ ክፍሉ ማስገባት
      _socket.emit('join_room', {
        'role': role,
        'userId': userId,
      });
    });

    _socket.onDisconnect((_) => print('❌ Socket ተቋርጧል'));
  }

  // ወጥ ቤት አዲስ ትዕዛዝ ሲመጣ እንዲሰማ (Listen for New Orders)
  void listenNewOrders(Function(dynamic data) onNewOrder) {
    _socket.on('kitchen:new_order', (data) {
      onNewOrder(data);
    });
  }

  // አስተናጋጅ ምግቡ አለቀ የሚል መልዕክት ሲደርሳት (Listen for Ready Alert)
  void listenOrderReady(Function(dynamic data) onReadyAlert) {
    _socket.on('order:ready_alert', (data) {
      onReadyAlert(data);
    });
  }

  void disconnect() {
    _socket.disconnect();
  }
}
