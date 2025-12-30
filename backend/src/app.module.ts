<<<<<<< HEAD
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { SocketModule } from './socket/socket.module';


@Module({
  imports: [
      PrismaModule,
      SocketModule,
      ],
  controllers: [AppController],
  providers: [AppService],
=======
import { Module } from "@nestjs/common";
import { PrismaModule } from "./database/prisma.module";
import { AuthModule } from "./modules/auth/auth.module";
import { UsersModule } from "./modules/users/users.module";

@Module({
  imports: [PrismaModule, AuthModule, UsersModule],
>>>>>>> 8af37495b4919a71eec88fa862703bbc5479915f
})
export class AppModule {}
