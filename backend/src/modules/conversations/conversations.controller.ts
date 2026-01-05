import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { ConversationsService } from './conversations.service';
import { CreateGroupDto } from './dto/create-group.dto';

@Controller('conversations')
export class ConversationsController {
  constructor(private readonly service: ConversationsService) {}

  @UseGuards(JwtAuthGuard)
  @Post('groups')
  createGroup(@Req() req: any, @Body() dto: CreateGroupDto) {
    const userId = req.user?.id || req.user?.sub; // hỗ trợ cả 2 kiểu
    return this.service.createGroup(userId, dto);
  }

}
