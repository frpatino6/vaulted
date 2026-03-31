import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { join } from 'node:path';
import { NestExpressApplication } from '@nestjs/platform-express';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const cookieParser = require('cookie-parser') as () => unknown;
import { AppModule } from './app.module';
import { ResponseInterceptor } from './common/interceptors/response.interceptor';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap(): Promise<void> {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Global prefix must be set BEFORE static assets so Express static
  // middleware is registered on the raw path without the /api prefix.
  app.setGlobalPrefix('api');

  const allowedOrigins = [
    'http://localhost:3000',
    'http://localhost:4200',
    'http://localhost:8080',
    'https://vaulted-prod-2026.web.app',
    'https://vaulted-prod-2026.firebaseapp.com',
    // Always allow the canonical API domain so CachedNetworkImage on Flutter
    // Web (CanvasKit) can fetch /uploads/* from the same host.
    'https://api-vaulted.casacam.net',
  ].filter(Boolean);

  app.enableCors({
    origin: allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  app.use(cookieParser());

  // Serve uploaded files at /uploads/* — must be registered after setGlobalPrefix
  // so NestJS routing does not intercept these paths.
  // The cors() middleware registered above runs before this handler, so all
  // /uploads responses include the correct Access-Control-Allow-Origin header,
  // which is required by Flutter Web (CanvasKit fetch API).
  app.useStaticAssets(join(process.cwd(), 'uploads'), {
    prefix: '/uploads',
    setHeaders: (res) => {
      // Belt-and-suspenders: explicitly set CORS headers on every static
      // file response so CanvasKit fetch() does not get blocked.
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    },
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.useGlobalInterceptors(new ResponseInterceptor());
  app.useGlobalFilters(new HttpExceptionFilter());

  const port = process.env['PORT'] ?? 3000;
  await app.listen(port);
  logger.log(`API running on port ${port}`);
}

bootstrap();
