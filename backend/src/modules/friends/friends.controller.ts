import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';

@Injectable()
export class FriendsService {
  constructor(private readonly prisma: PrismaService) {}

  async getRelations(userId: string) {
    // Lấy tất cả contacts (bạn bè)
    const contacts = await this.prisma.contact.findMany({
      where: { ownerId: userId },
      include: { friend: true },
    });

    // Lấy friend requests incoming/outgoing
    const incoming = await this.prisma.friendRequest.findMany({
      where: { toUserId: userId, status: 'PENDING' },
      include: { fromUser: true },
    });

    const outgoing = await this.prisma.friendRequest.findMany({
      where: { fromUserId: userId, status: 'PENDING' },
      include: { toUser: true },
    });

    // Map về dạng dùng cho Flutter
    const relations = [
      ...contacts.map(c => ({
        user: {
          id: c.contactId,
          username: c.friend.username,
          fullName: c.friend.fullName,
          avatarUrl: c.friend.avatarUrl,
        },
        status: 'friend',
      })),
      ...incoming.map(r => ({
        user: {
          id: r.fromUserId,
          username: r.fromUser.username,
          fullName: r.fromUser.fullName,
          avatarUrl: r.fromUser.avatarUrl,
        },
        status: 'incomingRequest',
        requestId: r.id,
      })),
      ...outgoing.map(r => ({
        user: {
          id: r.toUserId,
          username: r.toUser.username,
          fullName: r.toUser.fullName,
          avatarUrl: r.toUser.avatarUrl,
        },
        status: 'outgoingRequest',
        requestId: r.id,
      })),
    ];

    return relations;
  }
}
