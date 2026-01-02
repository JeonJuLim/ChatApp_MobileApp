import { Body, Controller, Get, Param, Patch, Post, Req } from '@nestjs/common';
import { ConversationsService } from './conversations.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateMembersDto } from './dto/update-members.dto';

@Controller('conversations')
export class ConversationsController {
  constructor(private readonly service: ConversationsService) {}

  // (1) Tạo group
  @Post('group')
  createGroup(@Req() req: any, @Body() dto: CreateGroupDto) {
    const userId = req.user.sub;
    return this.service.createGroup(userId, dto);
  }

  // (3) List group của user
  @Get('groups')
  listGroups(@Req() req: any) {
    const userId = req.user.sub;
    return this.service.listGroups(userId);
  }

  // ✅ (mới) lấy chi tiết group + members (để UI quản lý thành viên)
  @Get(':id')
  getGroup(@Req() req: any, @Param('id') id: string) {
    const userId = req.user.sub;
    return this.service.getGroup(userId, id);
  }

  // (2) Add / remove members
  @Patch(':id/members')
  updateMembers(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateMembersDto) {
    const userId = req.user.sub;
    return this.service.updateMembers(userId, id, dto);
  }
}
