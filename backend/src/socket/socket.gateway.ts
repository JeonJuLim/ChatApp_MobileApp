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
  cors: {
    origin: '*',
  },
})
export class SocketGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  constructor(private readonly socketService: SocketService) {}

  // =============================
  // CLIENT CONNECT
  // =============================
  handleConnection(client: Socket) {
    console.log('🟢 Client connected:', client.id);
  }

  // =============================
  // CLIENT DISCONNECT
  // =============================
  handleDisconnect(client: Socket) {
    console.log('🔴 Client disconnected:', client.id);
  }

  // =============================
  // JOIN CONVERSATION ROOM
  // =============================
  @SubscribeMessage('join_conversation')
  async handleJoinConversation(
    @MessageBody()
    data: { conversationId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    console.log(
      `👥 join_conversation | user=${data.userId} | room=${data.conversationId}`,
    );

    return this.socketService.joinConversation(client, data);
  }

  // =============================
  // SEND MESSAGE
  // =============================
  @SubscribeMessage('send_message')
  async handleSendMessage(
    @MessageBody()
    data: {
      conversationId: string;
      senderId: string;
      content: string;
    },
    @ConnectedSocket() client: Socket,
  ) {
    console.log(
      `📩 send_message | sender=${data.senderId} | room=${data.conversationId} | content=${data.content}`,
    );

    return this.socketService.sendMessage(client, data);
  }
}
