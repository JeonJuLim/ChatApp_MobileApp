import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { SocketService } from './socket.service';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  transports: ['websocket', 'polling'], // ✅ BẮT BUỘC
})
export class SocketGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  constructor(private readonly socketService: SocketService) {}

  handleConnection(client: Socket) {
    console.log('🟢 SOCKET CONNECTED:', client.id);
  }

  handleDisconnect(client: Socket) {
    console.log('🔴 SOCKET DISCONNECTED:', client.id);
  }

  // JOIN ROOM
  @SubscribeMessage('join_conversation')
  handleJoin(
    @MessageBody() data: { conversationId: string; userId: string },
    @ConnectedSocket() client: Socket,
  ) {
    client.join(data.conversationId);
    console.log(
      `👥 ${data.userId} joined room ${data.conversationId}`,
    );
  }

  // SEND MESSAGE
  @SubscribeMessage('send_message')
  handleMessage(
    @MessageBody()
    data: { conversationId: string; senderId: string; content: string },
  ) {
    console.log(
      `📩 ${data.senderId} -> ${data.conversationId}: ${data.content}`,
    );

    this.server
      .to(data.conversationId)
      .emit('new_message', data);
  }
}
