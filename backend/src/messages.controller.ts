import { Controller, Get, Param } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';


@Controller('messages')
export class MessagesController {
  constructor(private prisma: PrismaService) {}

  @Get(':conversationId')
  async getMessages(@Param('conversationId') conversationId: string) {
    return this.prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
    });
  }
}
