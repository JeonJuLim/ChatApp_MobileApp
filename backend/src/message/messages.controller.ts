import { Controller, Get, Param, Post, Body } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Controller('messages')
export class MessagesController {
  constructor(private prisma: PrismaService) {}

  // 📥 Load message history
  @Get(':conversationId')
  async getMessages(@Param('conversationId') conversationId: string) {
    return this.prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
      include: {
        sender: { select: { id: true, fullName: true } },
      },
    });
  }

  // 📤 Send message
  @Post()
  async sendMessage(
    @Body()
    body: {
      conversationId: string;
      senderId: string;
      content: string;
    },
  ) {
    return this.prisma.message.create({
      data: {
        conversationId: body.conversationId,
        senderId: body.senderId,
        content: body.content,
        type: 'text',
      },
    });
  }
}
