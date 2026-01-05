import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateMembersDto } from './dto/update-members.dto';

@Injectable()
export class ConversationsService {
  constructor(private readonly prisma: PrismaService) {}

  async createGroup(creatorId: string, dto: CreateGroupDto) {
    const memberIds = Array.from(
      new Set([creatorId, ...(dto.memberIds ?? [])]),
    );

    const conv = await this.prisma.conversation.create({
      data: {
        type: 'group',
        name: dto.name,
        avatarUrl: dto.avatarUrl ?? null,
        createdBy: creatorId,
        members: {
          create: memberIds.map((uid) => ({
            userId: uid,
            role: uid === creatorId ? 'admin' : 'member',
          })),
        },
      },
      include: { members: { include: { user: true } },
      },
    });

    return conv;
  }

  async listGroups(userId: string) {
    return this.prisma.conversation.findMany({
      where: {
        type: 'group',
        members: { some: { userId } },
      },
      orderBy: { createdAt: 'desc' }, // ✅ FIX
      include: {
        members: { include: { user: true } },
        messages: { take: 1, orderBy: { createdAt: 'desc' } },
      },
    });
  }

  async getGroup(userId: string, conversationId: string) {
    const mem = await this.prisma.conversationMember.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
    });
    if (!mem) throw new ForbiddenException('Bạn không thuộc nhóm');

    const conv = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { members: { include: { user: true } } },
    });
    if (!conv) throw new NotFoundException('Không tìm thấy nhóm');

    return conv;
  }

  private async requireAdmin(userId: string, conversationId: string) {
    const mem = await this.prisma.conversationMember.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
    });
    if (!mem) throw new ForbiddenException('Bạn không thuộc nhóm');
    if (mem.role !== 'admin') {
      throw new ForbiddenException('Chỉ admin mới được thao tác');
    }
  }

  async updateMembers(actorId: string, conversationId: string, dto: UpdateMembersDto) {
    await this.requireAdmin(actorId, conversationId);

    const conv = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });
    if (!conv) throw new NotFoundException('Không tìm thấy nhóm');

    const add = dto.add ?? [];
    const remove = dto.remove ?? [];

    const protectedIds = new Set([conv.createdBy]);

    if (add.length) {
      await this.prisma.conversationMember.createMany({
        data: add.map((uid) => ({
          conversationId,
          userId: uid,
          role: 'member',
        })),
        skipDuplicates: true,
      });
    }

    if (remove.length) {
      const filtered = remove.filter((uid) => !protectedIds.has(uid));
      if (filtered.length) {
        await this.prisma.conversationMember.deleteMany({
          where: {
            conversationId,
            userId: { in: filtered },
          },
        });
      }
    }

    return this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: { members: { include: { user: true } } },
    });
  }




}
