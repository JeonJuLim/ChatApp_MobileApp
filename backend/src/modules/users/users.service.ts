// backend/src/modules/users/users.service.ts
import { BadRequestException, ConflictException, Injectable, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../../database/prisma.service";

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async updatePhone(userId: string, phone?: string | null) {
    if (!userId) throw new BadRequestException("Missing userId");

    const normalized = phone == null || String(phone).trim() === ""
      ? null
      : String(phone).trim();

    const exists = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });
    if (!exists) throw new NotFoundException("User not found");

    try {
      const user = await this.prisma.user.update({
        where: { id: userId },
        data: { phone: normalized, phoneVerified: false },
        select: { id: true, email: true, phone: true, provider: true },
      });
      return { ok: true, user };
    } catch (e: any) {
      if (e?.code === "P2002") throw new ConflictException("Số điện thoại đã được sử dụng.");
      throw e;
    }
  }
}
