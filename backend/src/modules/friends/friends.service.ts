import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { FriendRequestStatus } from '@prisma/client';

@Injectable()
export class FriendsService {
  constructor(private readonly prisma: PrismaService) {}

  // ==================================================
  // GET RELATIONS: friend + incomingRequest + outgoingRequest
  // ==================================================
  async getRelations(myId: string) {
    // Friends (Contact)
    const contacts = await this.prisma.contact.findMany({
      where: { ownerId: myId },
      select: { contactId: true },
    });

    const contactIds = contacts.map(c => c.contactId);

    const friendsUsers = contactIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: contactIds } },
          select: {
            id: true,
            username: true,
            fullName: true,
            phoneE164: true,
            avatarUrl: true,
          },
        })
      : [];

    const friends = friendsUsers.map(u => ({
      status: 'friend',
      requestId: null,
      user: u,
    }));

    // Incoming requests
    const incoming = await this.prisma.friendRequest.findMany({
      where: { toUserId: myId, status: FriendRequestStatus.PENDING },
      select: {
        id: true,
        fromUser: {
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

    const incomingMapped = incoming.map(r => ({
      status: 'incomingRequest',
      requestId: r.id,
      user: r.fromUser,
    }));

    // Outgoing requests
    const outgoing = await this.prisma.friendRequest.findMany({
      where: { fromUserId: myId, status: FriendRequestStatus.PENDING },
      select: {
        id: true,
        toUser: {
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

    const outgoingMapped = outgoing.map(r => ({
      status: 'outgoingRequest',
      requestId: r.id,
      user: r.toUser,
    }));

    return [...friends, ...incomingMapped, ...outgoingMapped];
  }

  // ==================================================
  // SEND REQUEST BY USERNAME
  // ==================================================
  async requestByUsername(myId: string, username: string) {
    const u = (username ?? '').trim();
    if (!u) throw new BadRequestException('Username không hợp lệ');

    const to = await this.prisma.user.findUnique({ where: { username: u } });
    if (!to) throw new NotFoundException('Không tìm thấy user theo username');

    return this._createFriendRequest(myId, to.id);
  }

  // ==================================================
  // SEND REQUEST BY PHONE
  // ==================================================
  async requestByPhone(myId: string, phoneE164: string) {
    const p = (phoneE164 ?? '').trim();
    if (!p) throw new BadRequestException('Số điện thoại không hợp lệ');

    const to = await this.prisma.user.findUnique({ where: { phoneE164: p } });
    if (!to) throw new NotFoundException('Không tìm thấy user theo số điện thoại');

    return this._createFriendRequest(myId, to.id);
  }

  // ==================================================
  // ACCEPT FRIEND REQUEST
  // ==================================================
  async accept(myId: string, requestId: string) {
    const req = await this.prisma.friendRequest.findUnique({
      where: { id: requestId },
    });

    if (!req) throw new NotFoundException('Lời mời không tồn tại');
    if (req.toUserId !== myId)
      throw new BadRequestException('Không có quyền accept lời mời này');
    if (req.status !== FriendRequestStatus.PENDING)
      throw new ConflictException('Lời mời đã được xử lý');

    await this.prisma.$transaction([
      this.prisma.friendRequest.update({
        where: { id: requestId },
        data: { status: FriendRequestStatus.ACCEPTED },
      }),
      this.prisma.contact.createMany({
        data: [
          { ownerId: req.fromUserId, contactId: req.toUserId },
          { ownerId: req.toUserId, contactId: req.fromUserId },
        ],
        skipDuplicates: true,
      }),
    ]);

    return { ok: true };
  }

  // ==================================================
  // REJECT FRIEND REQUEST
  // ==================================================
  async reject(myId: string, requestId: string) {
    const req = await this.prisma.friendRequest.findUnique({
      where: { id: requestId },
    });

    if (!req) throw new NotFoundException('Lời mời không tồn tại');
    if (req.toUserId !== myId)
      throw new BadRequestException('Không có quyền reject lời mời này');
    if (req.status !== FriendRequestStatus.PENDING)
      throw new ConflictException('Lời mời đã được xử lý');

    await this.prisma.friendRequest.update({
      where: { id: requestId },
      data: { status: FriendRequestStatus.REJECTED },
    });

    return { ok: true };
  }

  // ==================================================
  // INTERNAL: create friend request (PENDING)
  // ==================================================
  private async _createFriendRequest(myId: string, otherId: string) {
    if (myId === otherId) {
      throw new BadRequestException('Không thể kết bạn với chính mình');
    }

    const existedContact = await this.prisma.contact.findFirst({
      where: { ownerId: myId, contactId: otherId },
      select: { id: true },
    });
    if (existedContact) throw new ConflictException('Đã là bạn bè');

    const existedReq = await this.prisma.friendRequest.findFirst({
      where: {
        status: FriendRequestStatus.PENDING,
        OR: [
          { fromUserId: myId, toUserId: otherId },
          { fromUserId: otherId, toUserId: myId },
        ],
      },
      select: { id: true },
    });
    if (existedReq) throw new ConflictException('Đã có lời mời đang chờ');

    const fr = await this.prisma.friendRequest.create({
      data: { fromUserId: myId, toUserId: otherId },
      select: { id: true },
    });

    return { ok: true, requestId: fr.id };
  }
}
