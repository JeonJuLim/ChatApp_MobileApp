import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class FriendsService {
  constructor(private readonly prisma: PrismaService) {}

  // GET /friends/relations
  async listRelations(myId: string) {
    // Lấy tất cả bạn của mình
    const rows = await this.prisma.contact.findMany({
      where: { ownerId: myId },
      include: {
        friend: {
          select: {
            id: true,
            username: true,
            fullName: true,
            phoneE164: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Trả đúng format Flutter đang parse
    return rows.map((c) => ({
      status: 'friend',
      requestId: null,
      user: c.friend,
    }));
  }

  // POST /friends/request-by-username
  // MVP: add thẳng 2 chiều (kết bạn ngay), không dùng FriendRequest
  async addFriendByUsername(myId: string, username: string) {
    const u = (username || '').trim();
    if (!u) throw new BadRequestException('username is required');

    const target = await this.prisma.user.findUnique({
      where: { username: u },
      select: { id: true, username: true, fullName: true, phoneE164: true, avatarUrl: true },
    });
    if (!target) throw new NotFoundException('User not found');

    if (target.id === myId) throw new BadRequestException('Cannot add yourself');

    // Tạo contact 2 chiều, tránh trùng bằng createMany + skipDuplicates
    await this.prisma.contact.createMany({
      data: [
        { ownerId: myId, contactId: target.id },
        { ownerId: target.id, contactId: myId },
      ],
      skipDuplicates: true,
    });

    return { ok: true };
  }
}
