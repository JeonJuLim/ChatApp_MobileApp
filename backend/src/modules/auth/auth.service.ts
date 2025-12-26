// backend/src/modules/auth/auth.service.ts
import { Injectable } from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { PrismaService } from "../../database/prisma.service";

import { RegisterEmailDto } from "./dto/register-email.dto";
import { LoginEmailDto } from "./dto/login-email.dto";
import { GoogleLoginDto } from "./dto/google-login.dto";

@Injectable()
export class AuthService {
  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  // ✅ STUB (để controller compile). Bạn sẽ implement chuẩn sau.
  async registerEmail(dto: RegisterEmailDto) {
    // TODO: tạo user bằng email, phone = null (cho phép điền sau)
    return { ok: true, action: "registerEmail", dto };
  }

  // ✅ STUB (để controller compile). Bạn sẽ implement chuẩn sau.
  async loginEmail(dto: LoginEmailDto) {
    // TODO: kiểm tra password, sign JWT có sub
    return { ok: true, action: "loginEmail", dto };
  }

  // ✅ Google login: tạo/find user rồi sign JWT có sub
  async loginGoogle(dto: GoogleLoginDto) {
    // MVP: dùng idToken làm googleId tạm thời
    const googleId = dto.idToken;

    let user = await this.prisma.user.findUnique({ where: { googleId } });
    if (!user) {
      user = await this.prisma.user.create({
        data: {
          provider: "GOOGLE",
          googleId,
          email: null,
          phone: null, // ✅ cho phép null
          emailVerified: false,
          phoneVerified: false,
        },
      });
    }

    const accessToken = await this.jwt.signAsync({
      sub: user.id, // ✅ BẮT BUỘC để update phone dùng req.user.sub
      email: user.email,
      provider: user.provider,
    });

    return { accessToken, user };
  }
}
