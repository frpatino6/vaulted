const PRODUCTION_ORIGINS = [
  'https://vaulted-prod-2026.web.app',
  'https://vaulted-prod-2026.firebaseapp.com',
  'https://vaulted.casacam.net',
] as const;

const DEVELOPMENT_ORIGINS = [
  'http://localhost:3000',
  'http://localhost:4200',
  'http://localhost:8080',
  'https://api-vaulted.casacam.net',
] as const;

const envOrigins = process.env['CORS_ALLOWED_ORIGINS']
  ?.split(',')
  .map((origin) => origin.trim())
  .filter((origin) => origin.length > 0);

export const ALLOWED_ORIGINS = envOrigins?.length
  ? envOrigins
  : process.env['NODE_ENV'] === 'production'
    ? [...PRODUCTION_ORIGINS]
    : [...DEVELOPMENT_ORIGINS];
