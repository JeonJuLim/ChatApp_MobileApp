
import { Body, Controller, Get, Patch, Query, Req, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@Req() req: any) {
    return this.usersService.getMe(req.user.sub);
  }

  // PUBLIC: check username
   @Get('username-available')
   usernameAvailable(@Query('u') u: string) {
     return this.usersService.isUsernameAvailable(u);
   }

   @UseGuards(JwtAuthGuard)
   @Patch('me/profile')
   updateMeProfile(@Req() req: any, @Body() dto: UpdateProfileDto) {
     return this.usersService.updateMeProfile(req.user.sub, dto);
   }


}
