import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './database/prisma.module';
import { AuthModule } from './modules/auth/auth.module';

@Module({
  imports: [
    PrismaModule,
    AuthModule, // ✅ BẮT BUỘC
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
