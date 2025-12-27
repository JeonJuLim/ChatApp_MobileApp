import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  SocketService._();
  static final SocketService I = SocketService._();

  IO.Socket? _socket;

  void connect(String url) {
    if (_socket != null && _socket!.connected) {
      print('✅ Socket already connected');
      return;
    }

    print('🌐 Connecting socket to: $url');

    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('🟢 SOCKET CONNECTED: id=${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      print('🔴 SOCKET DISCONNECTED');
    });

    _socket!.onConnectError((err) {
      print('❌ SOCKET CONNECT ERROR: $err');
    });

    _socket!.onError((err) {
      print('❌ SOCKET ERROR: $err');
    });
  }

  void joinConversation(String conversationId, String userId) {
    print('👥 EMIT join_conversation: userId=$userId | room=$conversationId');

    _socket?.emit('join_conversation', {
      'conversationId': conversationId,
      'userId': userId,
    });
  }

  void sendMessage(String conversationId, String senderId, String content) {
    print('📤 EMIT send_message: sender=$senderId | room=$conversationId | content=$content');

    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
    });
  }

  void onNewMessage(void Function(dynamic) handler) {
    print('👂 Listening event: new_message');
    _socket?.on('new_message', handler);
  }

  void offNewMessage() {
    _socket?.off('new_message');
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
