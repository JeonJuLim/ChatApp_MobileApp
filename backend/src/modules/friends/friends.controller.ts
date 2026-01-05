import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { FriendsService } from './friends.service';
import { FriendRequestByUsernameDto } from './dto/request-by-username.dto';
import { FriendRequestByPhoneDto } from './dto/request-by-phone.dto';
import { FriendRequestActionDto } from './dto/request-action.dto';

@UseGuards(JwtAuthGuard)
@Controller('friends')
export class FriendsController {
  constructor(private readonly friends: FriendsService) {}

  @Get('relations')
  getRelations(@Req() req: any) {
    return this.friends.getRelations(req.user.sub);
  }

  @Post('request')
  requestByPhone(@Req() req: any, @Body() dto: FriendRequestByPhoneDto) {
    return this.friends.requestByPhone(req.user.sub, dto.phoneE164);
  }

  @Post('request-by-username')
  requestByUsername(@Req() req: any, @Body() dto: FriendRequestByUsernameDto) {
    return this.friends.requestByUsername(req.user.sub, dto.username);
  }

  @Post('requests/accept')
  accept(@Req() req: any, @Body() dto: FriendRequestActionDto) {
    return this.friends.accept(req.user.sub, dto.requestId);
  }

  @Post('requests/reject')
  reject(@Req() req: any, @Body() dto: FriendRequestActionDto) {
    return this.friends.reject(req.user.sub, dto.requestId);
  }
}
