import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { SocketService } from './socket.service';

@WebSocketGateway({
  cors: { origin: '*', transports: ['websocket'] },
})
export class SocketGateway implements OnGatewayConnection, OnGatewayDisconnect {
  constructor(private readonly socketService: SocketService) {}

  handleConnection(client: Socket) {
    console.log('🟢 Client connected:', client.id);
  }

  handleDisconnect(client: Socket) {
    console.log('🔴 Client disconnected:', client.id);
    // Nếu muốn: có thể xử lý auto end call khi user disconnect (tùy MVP)
  }

  // =========================
  // JOIN ROOM
  // =========================
  @SubscribeMessage('join_conversation')
  async handleJoinConversation(
    @MessageBody() data: { conversationId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.joinConversation(client, data);
  }

  // =========================
  // CHAT
  // =========================
  @SubscribeMessage('send_message')
  async handleSendMessage(
    @MessageBody()
    data: { conversationId: string; senderId: string; content: string; type?: string },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.sendMessage(client, data);
  }

  @SubscribeMessage('typing_start')
  async typingStart(
    @MessageBody() data: { conversationId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.typingStart(client, data);
  }

  @SubscribeMessage('typing_stop')
  async typingStop(
    @MessageBody() data: { conversationId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.typingStop(client, data);
  }

  @SubscribeMessage('message_seen')
  async messageSeen(
    @MessageBody() data: { conversationId: string; userId: string; messageId: string },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.messageSeen(client, data);
  }

  @SubscribeMessage('message_delivered')
  async messageDelivered(
    @MessageBody() data: { conversationId: string; userId: string; messageId: string },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.messageDelivered(client, data);
  }

  // ==========================================================
  // ✅ CALL CONTROL (cho UI trạng thái + CallLog DB)
  // ==========================================================

  /**
   * Client emit: call:start
   * payload: {
   *   callId: string, conversationId: string,
   *   fromUserId: string, toUserId: string,
   *   type: 'audio'|'video'
   * }
   */
  @SubscribeMessage('call:start')
  async handleCallStart(
    @MessageBody()
    payload: {
      callId: string;
      conversationId: string;
      fromUserId: string;
      toUserId: string;
      type: 'audio' | 'video';
    },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.callStart(client, payload);
  }

  /**
   * Client emit: call:accept
   * payload: { callId, conversationId, fromUserId, toUserId }
   */
  @SubscribeMessage('call:accept')
  async handleCallAccept(
    @MessageBody()
    payload: {
      callId: string;
      conversationId: string;
      fromUserId: string;
      toUserId: string;
    },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.callAccept(client, payload);
  }

  /**
   * Client emit: call:reject
   * payload: { callId, conversationId, fromUserId, toUserId }
   */
  @SubscribeMessage('call:reject')
  async handleCallReject(
    @MessageBody()
    payload: {
      callId: string;
      conversationId: string;
      fromUserId: string;
      toUserId: string;
    },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.callReject(client, payload);
  }

  /**
   * Client emit: call:end
   * payload: { callId, conversationId, fromUserId, toUserId, duration? }
   * (duration gửi từ client khi end)
   */
  @SubscribeMessage('call:end')
  async handleCallEndControl(
    @MessageBody()
    payload: {
      callId: string;
      conversationId: string;
      fromUserId: string;
      toUserId: string;
      duration?: number;
    },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.callEnd(client, payload);
  }

  // ==========================================================
  // ✅ CALL SIGNALING (giữ y như bạn đang làm)
  // ==========================================================

@SubscribeMessage('call:offer')
handleCallOffer(@MessageBody() payload: any, @ConnectedSocket() client: Socket) {
  if (!payload?.conversationId || !payload?.callId) return;
  client.to(payload.conversationId).emit('call:offer', payload);
}

@SubscribeMessage('call:answer')
handleCallAnswer(@MessageBody() payload: any, @ConnectedSocket() client: Socket) {
  if (!payload?.conversationId || !payload?.callId) return;
  client.to(payload.conversationId).emit('call:answer', payload);
}

@SubscribeMessage('call:ice')
handleCallIce(@MessageBody() payload: any, @ConnectedSocket() client: Socket) {
  if (!payload?.conversationId || !payload?.callId) return;
  client.to(payload.conversationId).emit('call:ice', payload);
}
@SubscribeMessage('call:ready')
handleCallReady(
  @MessageBody() payload: { callId: string; conversationId: string; userId: string },
  @ConnectedSocket() client: Socket,
) {
  if (!payload?.conversationId || !payload?.callId) return;
  client.to(payload.conversationId).emit('call:ready', payload);
}

  // Lưu ý: call:end signaling bạn đã có; giờ call:end control đã xử lý ở trên
  // Nếu vẫn muốn relay signaling riêng, đổi tên event: call:signal_end hoặc call:hangup
}
