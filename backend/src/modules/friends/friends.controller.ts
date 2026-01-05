import { Controller, Get, Post, Body, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt.guard'; // hoặc guard bạn đang dùng
import { FriendsService } from './friends.service';

class SendRequestByUsernameDto {
  username!: string;
}

@Controller('friends')
@UseGuards(JwtAuthGuard)
export class FriendsController {
  constructor(private readonly friends: FriendsService) {}

  @Get('relations')
  async relations(@Req() req: any) {
    return this.friends.listRelations(req.user.sub);
  }

  @Post('request-by-username')
  async requestByUsername(@Req() req: any, @Body() dto: SendRequestByUsernameDto) {
    return this.friends.addFriendByUsername(req.user.sub, dto.username);
  }
}
