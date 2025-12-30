import { Module } from '@nestjs/common';
import { SocketGateway } from './socket.gateway';
import { SocketService } from './socket.service';
import { PrismaModule } from '../database/prisma.module';


@Module({
  imports: [PrismaModule],
  providers: [SocketGateway, SocketService],
})
export class SocketModule {}
