import { Controller, Get, Param, BadRequestException } from '@nestjs/common';
import { PrismaService } from './database/prisma.service';

@Controller('messages')
export class MessagesController {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * GET /messages/:conversationId
   * Lấy toàn bộ tin nhắn của 1 cuộc hội thoại
   */
  @Get(':conversationId')
  async getMessages(
    @Param('conversationId') conversationId: string,
  ) {
    if (!conversationId) {
      throw new BadRequestException('Missing conversationId');
    }

    return this.prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
      include: {
        sender: {
          select: {
            id: true,
            username: true,
            fullName: true,
            avatarUrl: true,
          },
        },
      },
    });
  }
}
