import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../database/prisma.service';
import * as bcrypt from 'bcryptjs';

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
  // PASSWORD LOGIN (DÙNG CHO FLUTTER)
  // identifier: username | email | phoneE164
  // ==================================================
  async loginWithPassword(identifier: string, password: string) {
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { username: identifier },
          { email: identifier },
          { phoneE164: identifier },
        ],
      },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Tài khoản hoặc mật khẩu không đúng');
    }

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Tài khoản hoặc mật khẩu không đúng');
    }

    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      authProvider: user.authProvider,
      username: user.username,
      email: user.email,
    });

    return {
      accessToken, // ✅ Flutter cần cái này
      user: {
        id: user.id,
        username: user.username,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
        email: user.email,
        phoneE164: user.phoneE164,
      },
    };
  }

  // ==================================================
  // EMAIL REGISTER (STUB)
  // ==================================================
  async registerEmail(dto: RegisterEmailDto) {
    return { ok: true, action: 'registerEmail', dto };
  }

  // ==================================================
  // EMAIL LOGIN (STUB)
  // ==================================================
  async loginEmail(dto: LoginEmailDto) {
    return { ok: true, action: 'loginEmail', dto };
  }

  // ==================================================
  // GOOGLE LOGIN
  // ==================================================
  async loginGoogle(dto: GoogleLoginDto) {
    const googleSub = dto.idToken;

    let user = await this.prisma.user.findUnique({ where: { googleSub } });

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
      sub: user.id,
      authProvider: user.authProvider,
      email: user.email,
    });

    return { accessToken, user };
  }
}
