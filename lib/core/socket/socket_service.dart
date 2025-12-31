import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  SocketService._();
  static final SocketService I = SocketService._();

  IO.Socket? _socket;

  bool get isConnected => _socket?.connected == true;

  void connect(String url, {VoidCallback? onConnected}) {
    if (_socket != null) return;

    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('🟢 SOCKET CONNECTED: id=${_socket!.id}');
      onConnected?.call();
    });

    _socket!.onDisconnect((_) => debugPrint('🔴 SOCKET DISCONNECTED'));
    _socket!.onConnectError((err) => debugPrint('❌ CONNECT ERROR: $err'));
    _socket!.onError((err) => debugPrint('❌ SOCKET ERROR: $err'));

    _socket!.connect();
  }

  void joinConversation(String conversationId, String userId) {
    if (!isConnected) return;
    _socket!.emit('join_conversation', {'conversationId': conversationId, 'userId': userId});
  }

  void sendMessage(String conversationId, String senderId, String content) {
    if (!isConnected) return;
    _socket!.emit('send_message', {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': 'text',
    });
  }

  // ✅ typing
  void typingStart(String conversationId, String userId) {
    if (!isConnected) return;
    _socket!.emit('typing_start', {'conversationId': conversationId, 'userId': userId});
  }

  void typingStop(String conversationId, String userId) {
    if (!isConnected) return;
    _socket!.emit('typing_stop', {'conversationId': conversationId, 'userId': userId});
  }

  // ✅ status
  void markDelivered(String conversationId, String userId, String messageId) {
    if (!isConnected) return;
    _socket!.emit('message_delivered', {
      'conversationId': conversationId,
      'userId': userId,
      'messageId': messageId,
    });
  }

  void markSeen(String conversationId, String userId, String messageId) {
    if (!isConnected) return;
    _socket!.emit('message_seen', {
      'conversationId': conversationId,
      'userId': userId,
      'messageId': messageId,
    });
  }

  // listeners
  void onNewMessage(void Function(dynamic) handler) => _socket?.on('new_message', handler);
  void offNewMessage() => _socket?.off('new_message');

  void onTyping(void Function(dynamic) handler) => _socket?.on('typing', handler);
  void offTyping() => _socket?.off('typing');

  void onMessageStatus(void Function(dynamic) handler) => _socket?.on('message_status', handler);
  void offMessageStatus() => _socket?.off('message_status');

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
