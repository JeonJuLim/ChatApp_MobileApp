import { Injectable } from '@nestjs/common';
import { Socket } from 'socket.io';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class SocketService {
  constructor(private readonly prisma: PrismaService) {}

  async joinConversation(
    client: Socket,
    data: { conversationId: string; userId: string },
  ) {
    client.join(data.conversationId);

    console.log(
      `👥 User ${data.userId} joined conversation ${data.conversationId}`,
    );

    return { joined: true };
  }

  async sendMessage(
    client: Socket,
    data: {
      conversationId: string;
      senderId: string;
      content: string;
    },
  ) {

    const message = await this.prisma.message.create({
      data: {
        conversationId: data.conversationId,
        senderId: data.senderId,
        content: data.content,
        type: 'text',
      },
      include: {
        sender: {
          select: { id: true, username: true, fullName: true },
        },
      },
    });


    client.to(data.conversationId).emit('new_message', message);


    return message;
  }
}
