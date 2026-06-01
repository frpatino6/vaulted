import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const cookieParser = require('cookie-parser') as () => unknown;
import { AppModule } from './app.module';
import { ResponseInterceptor } from './common/interceptors/response.interceptor';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { ALLOWED_ORIGINS } from './common/config/cors.constants';

async function bootstrap(): Promise<void> {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Global prefix keeps all API routes under /api.
  app.setGlobalPrefix('api');

  const allowedOrigins = [...ALLOWED_ORIGINS];

  // Security headers — must be registered before CORS and routes.
  // crossOriginResourcePolicy set to 'cross-origin' because the API is on
  // api-vaulted.casacam.net and the web app runs on vaulted.casacam.net
  // (different subdomains = cross-site). The CORS config below already
  // restricts allowed origins, so this is safe.
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      contentSecurityPolicy: false, // API-only server, no HTML served
    }),
  );

  app.enableCors({
    origin: allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  app.use(cookieParser());

  // Increase JSON body limit for base64 image payloads (AI vision endpoints)
  app.useBodyParser('json', { limit: '20mb' });

  // Uploaded media is intentionally not exposed via Express static assets.
  // All private inventory media must be accessed through /api/media/:token,
  // where MediaService validates the signed token, tenant prefix, and local path.

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.useGlobalInterceptors(new ResponseInterceptor());
  app.useGlobalFilters(new HttpExceptionFilter());

  if (process.env['NODE_ENV'] !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('Vaulted API')
      .setDescription('Premium home inventory management API')
      .setVersion('1.0')
      .addBearerAuth()
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api-docs', app, document);

    if (process.env['NODE_ENV'] === 'development') {
      const fs = require('fs');
      const path = require('path');
      const openApiPath = path.join(__dirname, '../../../../docs/openapi.json');
      fs.writeFileSync(openApiPath, JSON.stringify(document, null, 2));
    }
  }

  const port = process.env['PORT'] ?? 3000;
  await app.listen(port);
  logger.log(`API running on port ${port}`);
}

bootstrap();
