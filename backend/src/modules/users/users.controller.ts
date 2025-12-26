import { Body, Controller, Patch, Req, UseGuards } from "@nestjs/common";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { UsersService } from "./users.service";
import { UpdatePhoneDto } from "./dto/update-phone.dto";

@Controller("users")
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @UseGuards(JwtAuthGuard)
  @Patch("me/phone")
  updatePhone(@Req() req: any, @Body() dto: UpdatePhoneDto) {
    console.log("REQ.USER =", req.user); // ✅ log
    return this.usersService.updatePhone(req.user?.sub, dto.phone);
  }
}

