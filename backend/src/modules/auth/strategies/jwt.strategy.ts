import { Injectable } from "@nestjs/common";
import { PassportStrategy } from "@nestjs/passport";
import { ExtractJwt, Strategy } from "passport-jwt";

export type JwtPayload = {
  sub: string;          // userId trong DB
  email?: string;
  provider?: string;
};

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: process.env.JWT_SECRET || "dev_secret",
      ignoreExpiration: false,
    });
  }

  async validate(payload: JwtPayload) {
    // Đây là object sẽ gắn vào req.user
    // => req.user.sub sẽ có userId
    return payload;
  }
}
