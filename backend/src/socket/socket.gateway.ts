import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Socket, Server } from 'socket.io';
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
  }

  @SubscribeMessage('join_conversation')
  async handleJoinConversation(
    @MessageBody() data: { conversationId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.joinConversation(client, data);
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @MessageBody()
    data: { conversationId: string; senderId: string; content: string; type?: string },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.sendMessage(client, data);
  }

  // ✅ TYPING START
  @SubscribeMessage('typing_start')
  async typingStart(
    @MessageBody() data: { conversationId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.typingStart(client, data);
  }

  // ✅ TYPING STOP
  @SubscribeMessage('typing_stop')
  async typingStop(
    @MessageBody() data: { conversationId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    return this.socketService.typingStop(client, data);
  }

  // ✅ SEEN / DELIVERED
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
// ✅ CALL SIGNALING: OFFER
@SubscribeMessage('call:offer')
handleCallOffer(
  @MessageBody() payload: any,
  @ConnectedSocket() client: Socket,
) {
  // relay cho các user khác trong conversation room
  client.to(payload.conversationId).emit('call:offer', payload);
}

// ✅ CALL SIGNALING: ANSWER
@SubscribeMessage('call:answer')
handleCallAnswer(
  @MessageBody() payload: any,
  @ConnectedSocket() client: Socket,
) {
  client.to(payload.conversationId).emit('call:answer', payload);
}

// ✅ CALL SIGNALING: ICE
@SubscribeMessage('call:ice')
handleCallIce(
  @MessageBody() payload: any,
  @ConnectedSocket() client: Socket,
) {
  client.to(payload.conversationId).emit('call:ice', payload);
}

// ✅ CALL SIGNALING: END
@SubscribeMessage('call:end')
handleCallEnd(
  @MessageBody() payload: any,
  @ConnectedSocket() client: Socket,
) {
  client.to(payload.conversationId).emit('call:end', payload);
}
}
