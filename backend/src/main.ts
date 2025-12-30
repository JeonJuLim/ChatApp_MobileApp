import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.enableCors({ origin: true, credentials: true });

  app.useGlobalFilters({
    catch(exception: any, host: any) {
      // log full
      // eslint-disable-next-line no-console
      console.error('UNCAUGHT EXCEPTION:', exception);

      const ctx = host.switchToHttp();
      const res = ctx.getResponse();

      res.status(500).json({
        message: exception?.message ?? 'Internal server error',
      });
    },
  } as any);

  const port = Number(process.env.PORT || 3001);
  await app.listen(port, '0.0.0.0');
  console.log(`API running at http://0.0.0.0:${port}`);
}
bootstrap();
