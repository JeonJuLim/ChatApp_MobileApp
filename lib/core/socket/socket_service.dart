import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  SocketService._();
  static final SocketService I = SocketService._();

  IO.Socket? _socket;
  bool _listenersAttached = false;

  bool get isConnected => _socket?.connected == true;

  void connect(String url, {VoidCallback? onConnected}) {
    // ✅ Nếu socket đã tồn tại:
    if (_socket != null) {
      // nếu đã connected -> gọi callback luôn
      if (_socket!.connected) {
        onConnected?.call();
        return;
      }

      // nếu chưa connected -> connect lại
      debugPrint('🔁 Reconnecting socket to: $url');
      _socket!.connect();
      return;
    }

    debugPrint('🌐 Connecting socket to: $url');

    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['polling', 'websocket']) // ✅ handshake ok
          .enableReconnection()                   // ✅ tự reconnect
          .setReconnectionAttempts(9999)
          .setReconnectionDelay(500)
          .setTimeout(8000)
          .enableAutoConnect()
          .build(),
    );

    // ✅ Attach listeners 1 lần
    if (!_listenersAttached) {
      _listenersAttached = true;

      _socket!.onConnect((_) {
        debugPrint('🟢 SOCKET CONNECTED: id=${_socket!.id}');
        onConnected?.call();
      });

      _socket!.onDisconnect((_) {
        debugPrint('🔴 SOCKET DISCONNECTED');
      });

      _socket!.onConnectError((err) {
        debugPrint('❌ SOCKET CONNECT ERROR: $err');
      });

      _socket!.onError((err) {
        debugPrint('❌ SOCKET ERROR: $err');
      });

      _socket!.onReconnect((_) {
        debugPrint('🟡 SOCKET RECONNECTED');
      });

      _socket!.onReconnectAttempt((_) {
        debugPrint('🟠 SOCKET RECONNECT ATTEMPT...');
      });
    }
  }

  void joinConversation(String conversationId, String userId) {
    if (!isConnected) {
      debugPrint('⚠️ Cannot join, socket not connected');
      return;
    }

    debugPrint('👥 EMIT join_conversation: userId=$userId | room=$conversationId');

    _socket!.emit('join_conversation', {
      'conversationId': conversationId,
      'userId': userId,
    });
  }

  void sendMessage(String conversationId, String senderId, String content) {
    if (!isConnected) {
      debugPrint('⚠️ Cannot send, socket not connected');
      return;
    }

    debugPrint('📤 EMIT send_message: sender=$senderId | room=$conversationId | content=$content');

    _socket!.emit('send_message', {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
    });
  }

  void onNewMessage(void Function(dynamic) handler) {
    _socket?.on('new_message', handler);
  }

  void offNewMessage() {
    _socket?.off('new_message');
  }

  // ✅ nếu muốn đóng hẳn socket khi logout/app exit
  void dispose() {
    _socket?.dispose();
    _socket = null;
    _listenersAttached = false;
  }
}
