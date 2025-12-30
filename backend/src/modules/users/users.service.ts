// backend/src/modules/users/users.service.ts
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async updatePhone(userId: string, phoneE164?: string | null) {
    if (!userId) {
      throw new BadRequestException('Missing userId');
    }

    const normalized =
      phoneE164 == null || String(phoneE164).trim() === ''
        ? null
        : String(phoneE164).trim();

    const exists = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!exists) {
      throw new NotFoundException('User not found');
    }

    try {
      const user = await this.prisma.user.update({
        where: { id: userId },
        data: {
          phoneE164: normalized,
          phoneVerifiedAt: null, // reset OTP verify
        },
        select: {
          id: true,
          email: true,
          phoneE164: true,
          authProvider: true,
        },
      });

      return { ok: true, user };
    } catch (e: any) {
      // Unique constraint (phoneE164)
      if (e?.code === 'P2002') {
        throw new ConflictException('Số điện thoại đã được sử dụng.');
      }
      throw e;
    }
  }
}
