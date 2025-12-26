import { Injectable } from "@nestjs/common";
import { PassportStrategy } from "@nestjs/passport";
import { ExtractJwt, Strategy } from "passport-jwt";

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: process.env.JWT_SECRET || "dev_secret",
    });
  }

  async validate(payload: any) {
    // ✅ quan trọng: phải trả về sub
    return {
      sub: payload.sub,
      email: payload.email,
      provider: payload.provider,
    };
  }
}
