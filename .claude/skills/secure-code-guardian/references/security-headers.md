# Security Headers & Rate Limiting Guide

Guidance for configuring HTTP security headers (via Helmet or equivalent) and rate limiting to harden API and web surfaces.

## Core Security Headers

| Header | Purpose | Recommended value |
|---|---|---|
| `Content-Security-Policy` | Restricts sources for scripts, styles, images, etc. — primary XSS mitigation | `default-src 'self'; script-src 'self'; object-src 'none'; frame-ancestors 'none'` (tune per app needs) |
| `Strict-Transport-Security` (HSTS) | Forces browsers to use HTTPS | `max-age=63072000; includeSubDomains; preload` |
| `X-Frame-Options` | Prevents clickjacking via framing | `DENY` (or use `frame-ancestors` in CSP) |
| `X-Content-Type-Options` | Prevents MIME-sniffing | `nosniff` |
| `Referrer-Policy` | Controls how much referrer info is leaked | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | Restricts browser feature access (camera, geolocation, etc.) | `camera=(), microphone=(), geolocation=()` (allowlist only what's needed) |
| `Cross-Origin-Resource-Policy` / `Cross-Origin-Opener-Policy` | Mitigates cross-origin info leaks (Spectre-class attacks) | `same-origin` |

### Setting headers with Helmet (Express/NestJS)
```typescript
import helmet from 'helmet';

app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        objectSrc: ["'none'"],
        frameAncestors: ["'none'"],
      },
    },
    hsts: { maxAge: 63072000, includeSubDomains: true, preload: true },
  }),
);
```

### Validating headers
- Use `curl -I https://your-api/health` to inspect response headers.
- Run an automated scan with Mozilla Observatory or `securityheaders.com` and address any findings below grade A.

## CORS Configuration
- Define an **explicit allowlist** of trusted origins — never `Access-Control-Allow-Origin: *` on endpoints that require credentials.
- Set `credentials: true` only for allowlisted origins, and never combine it with a wildcard origin (browsers reject this combination, and it signals a misconfigured policy).
- Restrict allowed methods and headers to what the API actually needs (`Access-Control-Allow-Methods`, `Access-Control-Allow-Headers`).
- Re-validate the CORS allowlist whenever new frontend domains (staging, preview deployments) are added.

```typescript
app.enableCors({
  origin: ['https://vaulted-prod-2026.web.app', 'https://app.vaulted.example'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
});
```

## Rate Limiting

### Why
- Slows brute-force attacks against authentication and OTP/MFA endpoints.
- Protects against credential stuffing and resource-exhaustion (DoS-style) abuse.
- Provides a signal for anomaly detection/logging (see `owasp-prevention.md` — A09).

### Implementation
```typescript
import rateLimit from 'express-rate-limit';

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,                   // 10 attempts per window per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts, please try again later' },
});

app.post('/api/login', authLimiter, loginHandler);
```

### Guidelines
- Apply **stricter limits** to authentication, password-reset, MFA, and token-refresh endpoints than to general read endpoints.
- Layer limits at multiple levels where possible: reverse proxy/WAF (e.g., Cloudflare), application middleware, and per-tenant/per-user quotas (e.g., Vaulted's `AI_CHAT_RATE_LIMIT_PER_MINUTE`).
- Use a shared store (Redis) for rate-limit counters in multi-instance deployments — in-memory counters don't scale horizontally.
- Return `429 Too Many Requests` with a `Retry-After` header, and log repeated violations as security events.
- Cap request payload sizes (`express.json({ limit: '10kb' })`) to prevent large-body resource exhaustion.

## Quick Checklist
- [ ] Helmet (or equivalent) configures CSP, HSTS, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`
- [ ] CORS restricted to an explicit origin allowlist; no wildcard with credentials
- [ ] Headers verified with `curl -I` or an automated scanner (target grade A)
- [ ] Rate limiting applied to auth/sensitive endpoints, backed by a shared store (Redis) in multi-instance setups
- [ ] Payload size limits configured on body parsers
- [ ] Rate-limit violations logged as security events

## References
- OWASP Secure Headers Project
- Helmet.js documentation — https://helmetjs.github.io
- OWASP REST Security Cheat Sheet (rate limiting section)
- Mozilla Observatory — https://observatory.mozilla.org
