// backend/src/modules/auth/auth.service.ts
import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../database/prisma.service';

import { RegisterEmailDto } from './dto/register-email.dto';
import { LoginEmailDto } from './dto/login-email.dto';
import { GoogleLoginDto } from './dto/google-login.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
  ) {}

  // ==================================================
  // EMAIL REGISTER (STUB – để Trang implement sau)
  // ==================================================
  async registerEmail(dto: RegisterEmailDto) {
    // TODO (Trang): hash password, validate email
    return {
      ok: true,
      action: 'registerEmail',
      dto,
    };
  }

  // ==================================================
  // EMAIL LOGIN (STUB – để Trang implement sau)
  // ==================================================
  async loginEmail(dto: LoginEmailDto) {
    // TODO (Trang): verify password, sign JWT
    return {
      ok: true,
      action: 'loginEmail',
      dto,
    };
  }

  // ==================================================
  // GOOGLE LOGIN (MVP – DÙNG ĐƯỢC NGAY)
  // ==================================================
  async loginGoogle(dto: GoogleLoginDto) {
    // ⚠️ MVP: dùng idToken làm googleSub tạm
    const googleSub = dto.idToken;

    let user = await this.prisma.user.findUnique({
      where: { googleSub },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          googleSub,
          authProvider: 'google',
           username: `google_${Date.now()}`,
                fullName: 'Google User',
          email: null,
          phoneE164: null,
          phoneVerifiedAt: null,
        },
      });
    }

    const accessToken = await this.jwt.signAsync({
      sub: user.id,               // ✅ RẤT QUAN TRỌNG
      authProvider: user.authProvider,
      email: user.email,
    });

    return {
      accessToken,
      user,
    };
  }
}
