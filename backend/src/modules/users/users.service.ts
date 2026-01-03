import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string) {
    return this.prisma.user.findUnique({ where: { id: userId } });
  }

  async isUsernameAvailable(raw: string) {
    const u = (raw ?? '').trim();

    if (!u) throw new BadRequestException('Missing username');

    // Rule gợi ý: a-z 0-9 _ . , dài 3-20 (giống Instagram-lite)
    const ok = /^[a-z0-9._]{3,20}$/i.test(u);
    if (!ok) {
      throw new BadRequestException(
        'Username không hợp lệ (3-20 ký tự, chỉ chữ/số/._)',
      );
    }

    const exists = await this.prisma.user.findUnique({
      where: { username: u },
      select: { id: true },
    });

    return { ok: true, username: u, available: !exists };
  }

  async updateMeProfile(userId: string, dto: any) {
    // bạn giữ logic update ở đây
    return this.prisma.user.update({
      where: { id: userId },
      data: dto,
    });
  }
}
