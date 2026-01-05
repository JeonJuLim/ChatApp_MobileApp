import { Module } from '@nestjs/common';

import { AppController } from './app.controller';
import { AppService } from './app.service';

import { PrismaModule } from './database/prisma.module';
import { SocketModule } from './socket/socket.module';

import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';

import { MessagesController } from './messages.controller';
import { ConversationsController } from './conversations.controller';
import { FriendsModule } from './modules/friends/friends.module';
import { HealthController } from './health.controller';
import { ConversationsModule } from './conversations/conversations.module';
@Module({
  imports: [
    PrismaModule,
    SocketModule,
    AuthModule,
    UsersModule,
    FriendsModule,
    ConversationsModule,
  ],
  controllers: [
    AppController,
    MessagesController,
    ConversationsController,
    HealthController,

  ],
  providers: [AppService],
})
export class AppModule {}
