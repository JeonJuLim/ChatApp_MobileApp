import { Body, Controller,Get, Post, Req, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { ConversationsService } from './conversations.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { BadRequestException,ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
@Controller('conversations')
export class ConversationsController {
  constructor(private readonly service: ConversationsService) {}
@UseGuards(JwtAuthGuard)
 @UseGuards(JwtAuthGuard)
 @Get()
 listMine(@Req() req: any) {
   const userId = req.user.id ?? req.user.sub;
   return this.service.listMine(userId);
 }
  @UseGuards(JwtAuthGuard)
  @Post('groups')
  createGroup(@Req() req: any, @Body() dto: CreateGroupDto) {
    const userId = req.user?.id || req.user?.sub; // hỗ trợ cả 2 kiểu
    return this.service.createGroup(userId, dto);
  }
 @UseGuards(JwtAuthGuard)
  @Post('direct')
  direct(@Req() req: any, @Body() body: { peerUserId: string }) {
    const myId = req.user?.id ?? req.user?.sub;
    return this.service.ensureDirectConversation(myId, body.peerUserId);
  }

}
