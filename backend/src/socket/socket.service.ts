import { Injectable } from '@nestjs/common';
import { Socket } from 'socket.io';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SocketService {
  constructor(private prisma: PrismaService) {}

  async joinConversation(client: Socket, data: { conversationId: string; userId: string }) {
    client.join(data.conversationId);
    console.log(`User ${data.userId} joined conversation ${data.conversationId}`);
    return { joined: true };
  }

  async sendMessage(client: Socket, data: any) {
    const message = {
      id: Date.now().toString(),
      conversationId: data.conversationId,
      senderId: data.senderId,
      content: data.content,
      createdAt: new Date(),
    };

    client.to(data.conversationId).emit('new_message', message);
    return message;
  }
}
