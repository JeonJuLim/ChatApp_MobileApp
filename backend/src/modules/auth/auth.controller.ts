import { Body, Controller, Post } from "@nestjs/common";
import { AuthService } from "./auth.service";
import { RegisterEmailDto } from "./dto/register-email.dto";
import { LoginEmailDto } from "./dto/login-email.dto";
import { GoogleLoginDto } from "./dto/google-login.dto";

@Controller("auth")
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post("register-email")
  registerEmail(@Body() dto: RegisterEmailDto) {
    return this.authService.registerEmail(dto);
  }

  @Post("login-email")
  loginEmail(@Body() dto: LoginEmailDto) {
    return this.authService.loginEmail(dto);
  }

  @Post("login-google")
  loginGoogle(@Body() dto: GoogleLoginDto) {
    return this.authService.loginGoogle(dto);
  }
}
