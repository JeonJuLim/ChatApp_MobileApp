import { Controller, Get, Query } from '@nestjs/common';
import { PrismaService } from './database/prisma.service';

@Controller('legacy/conversations')
export class ConversationsController {
  constructor(private prisma: PrismaService) {}

  @Get()
  async getConversations(@Query('userId') userId: string) {
    const conversations = await this.prisma.conversation.findMany({
      where: {
        members: {
          some: { userId },
        },
      },
      include: {
        members: {
          include: { user: true },
        },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    return conversations.map((c) => {
      const other = c.members.find(
        (m) => m.userId !== userId,
      )?.user;

      return {
        id: c.id,
        type: c.type,
        title: c.type === 'group'
          ? c.name
          : other?.fullName ?? 'Unknown',
        avatarUrl: c.avatarUrl ?? other?.avatarUrl,
        lastMessage: c.messages[0]?.content ?? '',
        lastMessageAt: c.messages[0]?.createdAt,
        unreadCount: 0,
      };
    });
  }

}
