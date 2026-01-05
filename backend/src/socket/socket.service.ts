import { Injectable } from '@nestjs/common';
import { Socket } from 'socket.io';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class SocketService {
  constructor(private readonly prisma: PrismaService) {}

  async joinConversation(client: Socket, data: { conversationId: string; userId: string }) {
    client.join(data.conversationId);
    client.emit('joined_conversation', { ok: true, conversationId: data.conversationId });
    return { ok: true };
  }

  // ✅ SEND MESSAGE -> save DB + emit new_message
  async sendMessage(
    client: Socket,
    data: { conversationId: string; senderId: string; content: string; type?: string },
  ) {
    const msg = await this.prisma.message.create({
      data: {
        conversationId: data.conversationId,
        senderId: data.senderId,
        content: data.content,
        type: data.type ?? 'text',
      },
      select: {
        id: true,
        content: true,
        type: true,
        createdAt: true,
        senderId: true,
        conversationId: true,
      },
    });

    // ✅ Emit cho tất cả trong room (bao gồm cả sender)
    client.to(data.conversationId).emit('new_message', msg);
    client.emit('new_message', msg);

    // ✅ Auto mark delivered cho tất cả members khác sender (tuỳ bạn)
    // Ở MVP: client nhận new_message thì gọi message_delivered.

    return { ok: true, message: msg };
  }

  // =========================
  // ✅ TYPING
  // =========================
  async typingStart(client: Socket, data: { conversationId: string; userId: string }) {
    // gửi cho người khác trong room
    client.to(data.conversationId).emit('typing', {
      conversationId: data.conversationId,
      userId: data.userId,
      isTyping: true,
    });
    return { ok: true };
  }

  async typingStop(client: Socket, data: { conversationId: string; userId: string }) {
    client.to(data.conversationId).emit('typing', {
      conversationId: data.conversationId,
      userId: data.userId,
      isTyping: false,
    });
    return { ok: true };
  }

  // =========================
  // ✅ DELIVERED / SEEN
  // =========================
  async messageDelivered(
    client: Socket,
    data: { conversationId: string; userId: string; messageId: string },
  ) {
    await this.prisma.messageStatus.upsert({
      where: {
        messageId_userId: { messageId: data.messageId, userId: data.userId },
      },
      update: { status: 'delivered' },
      create: { messageId: data.messageId, userId: data.userId, status: 'delivered' },
    });

    // broadcast trạng thái
    client.to(data.conversationId).emit('message_status', {
      messageId: data.messageId,
      userId: data.userId,
      status: 'delivered',
    });

    return { ok: true };
  }

  async messageSeen(client: Socket, data: { conversationId: string; userId: string; messageId: string }) {
    await this.prisma.messageStatus.upsert({
      where: {
        messageId_userId: { messageId: data.messageId, userId: data.userId },
      },
      update: { status: 'seen' },
      create: { messageId: data.messageId, userId: data.userId, status: 'seen' },
    });

    client.to(data.conversationId).emit('message_status', {
      messageId: data.messageId,
      userId: data.userId,
      status: 'seen',
    });

    return { ok: true };
  }

}
