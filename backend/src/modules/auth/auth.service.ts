import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
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

  // =========================
  // Helpers
  // =========================
  private normalizeEmail(email: string) {
    return email.trim().toLowerCase();
  }

  private normalizeIdentifier(identifier: string) {
    const s = identifier.trim();
    // nếu là email thì normalize lowercase
    if (/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(s)) return s.toLowerCase();
    return s;
  }

  private async signAccessToken(user: {
    id: string;
    authProvider: string;
    username: string;
    email: string | null;
  }) {
    return this.jwt.signAsync({
      sub: user.id,
      authProvider: user.authProvider,
      username: user.username,
      email: user.email,
    });
  }

  private generateUsernameFromEmail(email: string) {
    // tram9@gmail.com -> tram9_12345 (tránh trùng)
    const base = email
      .split('@')[0]
      .replace(/[^a-zA-Z0-9_.]/g, '')
      .toLowerCase();

    const suffix = (Date.now() % 100000).toString().padStart(5, '0');
    const u = `${base}_${suffix}`;
    return u.length > 20 ? u.substring(0, 20) : u;
  }

  // ==================================================
  // PASSWORD LOGIN (DÙNG CHO FLUTTER)
  // identifier: username | email | phoneE164
  // ==================================================
  async loginWithPassword(identifier: string, password: string) {
    const id = this.normalizeIdentifier(identifier);

    const user = await this.prisma.user.findFirst({
      where: {
        OR: [{ username: id }, { email: id }, { phoneE164: id }],
      },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Tài khoản hoặc mật khẩu không đúng');
    }

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Tài khoản hoặc mật khẩu không đúng');
    }

    const accessToken = await this.signAccessToken({
      id: user.id,
      authProvider: user.authProvider,
      username: user.username,
      email: user.email,
    });

    return {
      accessToken,
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
  // EMAIL REGISTER (REAL)
  // POST /auth/register-email
  // ==================================================
  async registerEmail(dto: RegisterEmailDto) {
    const email = this.normalizeEmail(dto.email);
    const password = dto.password;

    if (!email) throw new BadRequestException('Email is required');
    if (!password || password.length < 6) {
      throw new BadRequestException('Mật khẩu tối thiểu 6 ký tự');
    }

    // check duplicate email
    const existed = await this.prisma.user.findUnique({
      where: { email },
      select: { id: true },
    });
    if (existed) {
      throw new ConflictException('Email đã được sử dụng');
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const username = this.generateUsernameFromEmail(email);
    const fullName = dto.fullName?.trim() || 'New User';

    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        authProvider: 'password',
        username,
        fullName,

        // email-first: phone bổ sung sau
        phoneE164: null,
        phoneVerifiedAt: null,
        phoneVerifyRequired: false,

        // tuỳ bạn: mới đăng ký thì chưa verified
        emailVerifiedAt: null,
        status: 'offline',
      },
      select: {
        id: true,
        username: true,
        fullName: true,
        avatarUrl: true,
        email: true,
        phoneE164: true,
        authProvider: true,
      },
    });

    const accessToken = await this.signAccessToken({
      id: user.id,
      authProvider: user.authProvider,
      username: user.username,
      email: user.email,
    });

    return { accessToken, user };
  }

  // ==================================================
  // EMAIL LOGIN (REAL)
  // POST /auth/login-email
  // ==================================================
  async loginEmail(dto: LoginEmailDto) {
    const email = this.normalizeEmail(dto.email);
    const password = dto.password;

    const user = await this.prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        username: true,
        fullName: true,
        avatarUrl: true,
        email: true,
        phoneE164: true,
        authProvider: true,
        passwordHash: true,
      },
    });

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Tài khoản hoặc mật khẩu không đúng');
    }

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Tài khoản hoặc mật khẩu không đúng');
    }

    const accessToken = await this.signAccessToken({
      id: user.id,
      authProvider: user.authProvider,
      username: user.username,
      email: user.email,
    });

    const { passwordHash, ...safeUser } = user;
    return { accessToken, user: safeUser };
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
          phoneVerifyRequired: false,
        },
      });
    }

    const accessToken = await this.signAccessToken({
      id: user.id,
      authProvider: user.authProvider,
      username: user.username,
      email: user.email,
    });

    return { accessToken, user };
  }
}
