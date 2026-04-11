import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { join } from 'node:path';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
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
    // Allow the canonical API domain so Flutter Web (CanvasKit) can fetch
    // /uploads/* when the web app and API share the same hostname.
    'https://api-vaulted.casacam.net',
  ].filter(Boolean);

  // Security headers — must be registered before CORS and routes.
  // crossOriginResourcePolicy is set to same-site so uploaded media files
  // can be fetched by the Flutter Web app (same eTLD+1: casacam.net).
  app.use(helmet({
    crossOriginResourcePolicy: { policy: 'same-site' },
    contentSecurityPolicy: false, // API-only server, no HTML served
  }));

  app.enableCors({
    origin: allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  app.use(cookieParser());

  // Serve uploaded files at /uploads/*.
  // CORS for /uploads is handled per-request: only set the header when
  // the request Origin is in the allowedOrigins list. This prevents any
  // third-party site from fetching private inventory media.
  app.use('/uploads', (
    req: import('express').Request,
    res: import('express').Response,
    next: import('express').NextFunction,
  ) => {
    const origin = req.headers['origin'] as string | undefined;
    if (origin && (allowedOrigins as string[]).includes(origin)) {
      res.setHeader('Access-Control-Allow-Origin', origin);
      res.setHeader('Vary', 'Origin');
    }
    next();
  });

  app.useStaticAssets(join(process.cwd(), 'uploads'), {
    prefix: '/uploads',
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
