import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard'; // chỉnh path guard theo project bạn
import { FriendsService } from './friends.service';

@Controller('friends')
export class FriendsController {
  constructor(private readonly friendsService: FriendsService) {}

  @UseGuards(JwtAuthGuard)
  @Get('relations')
  async getRelations(@Req() req: any) {
    const userId = req.user?.id;
    return this.friendsService.getRelations(userId);
  }
}
