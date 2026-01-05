import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { FriendsService } from './friends.service';

@Controller('friends')
export class FriendsController {
  constructor(private readonly friendsService: FriendsService) {}

  @UseGuards(JwtAuthGuard)
  @Get('relations')
  getRelations(@Req() req: any) {
    const userId = req.user?.id ?? req.user?.sub;
    return this.friendsService.getRelations(userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get()
  listFriends(@Req() req: any) {
    const userId = req.user?.id ?? req.user?.sub;
    return this.friendsService.listFriends(userId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('request-by-username')
  requestByUsername(@Req() req: any, @Body() body: { username: string }) {
    const userId = req.user?.id ?? req.user?.sub;
    return this.friendsService.requestByUsername(userId, body.username);
  }

  @UseGuards(JwtAuthGuard)
  @Post('requests/accept')
  accept(@Req() req: any, @Body() body: { requestId: string }) {
    const userId = req.user?.id ?? req.user?.sub;
    return this.friendsService.accept(userId, body.requestId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('requests/reject')
  reject(@Req() req: any, @Body() body: { requestId: string }) {
    const userId = req.user?.id ?? req.user?.sub;
    return this.friendsService.reject(userId, body.requestId);
  }
}
