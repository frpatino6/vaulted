# XSS & CSRF — Prevention Guide

Guidance for preventing Cross-Site Scripting (XSS) and Cross-Site Request Forgery (CSRF) in web applications and APIs.

## Cross-Site Scripting (XSS)

### Types
- **Stored XSS**: malicious script saved server-side (e.g., in a comment or item description) and served to other users.
- **Reflected XSS**: malicious script embedded in a request (URL/query param) and echoed back in the response.
- **DOM-based XSS**: client-side code writes untrusted data into the DOM unsafely (`innerHTML`, `document.write`, `eval`).

### Prevention
- **Output encoding by context**: encode data for the context it's rendered in — HTML body, HTML attribute, JS string, URL, CSS. Use the templating engine's auto-escaping (React/Flutter widgets escape by default — avoid bypassing it).
- **Never use raw HTML injection** (`dangerouslySetInnerHTML`, `innerHTML`, `Html.fromHtml` with untrusted input) unless the content is sanitized through a vetted library (e.g., DOMPurify) with a strict allowlist.
- **Validate and constrain input** at the boundary (see `input-validation.md`) — reject or strip script tags, event handlers (`onerror`, `onclick`), and `javascript:` URLs.
- **Content Security Policy (CSP)**: set a strict CSP (`default-src 'self'`; avoid `unsafe-inline`/`unsafe-eval`) as defense in depth — see `security-headers.md`.
- **Cookie flags**: mark session/auth cookies `httpOnly` so they cannot be read via `document.cookie` even if an XSS payload executes.

### Example — safe vs. unsafe rendering
```typescript
// UNSAFE — renders raw user input as HTML
element.innerHTML = userComment;

// SAFE — escaped by default via templating/framework
<p>{userComment}</p>            // React/JSX auto-escapes
Text(userComment)               // Flutter widgets auto-escape

// If raw HTML is genuinely required, sanitize first:
import DOMPurify from 'dompurify';
element.innerHTML = DOMPurify.sanitize(userComment, { ALLOWED_TAGS: ['b', 'i', 'em'] });
```

## Cross-Site Request Forgery (CSRF)

CSRF tricks an authenticated user's browser into submitting a request to your API without their consent (e.g., via an auto-submitting form on a malicious site).

### When it applies
- Primarily a risk for **cookie-based session/auth** (the browser automatically attaches cookies to cross-site requests).
- APIs that authenticate exclusively via an `Authorization: Bearer <token>` header (not auto-attached by the browser) are inherently less exposed to classic CSRF — but if refresh tokens live in cookies, the cookie-bearing endpoints (e.g., `/auth/refresh`, `/auth/logout`) still need protection.

### Prevention
- **SameSite cookies**: set `SameSite=Strict` (or `Lax` where cross-site navigation must work) on auth/session cookies — this is the primary modern defense.
- **CSRF tokens**: for state-changing endpoints that rely on cookies, issue a per-session (or per-request) anti-CSRF token, embed it in forms/headers, and verify it server-side using the double-submit-cookie or synchronizer-token pattern.
- **Verify `Origin`/`Referer` headers** on state-changing requests as an additional check — reject mismatches.
- **Require re-authentication or step-up confirmation** for sensitive operations (changing email/password, payment details, deleting data) regardless of session validity.

### Example — double-submit cookie pattern
```typescript
// On session creation: set a random token both as a cookie and expose it to the client
res.cookie('csrf-token', token, { httpOnly: false, sameSite: 'strict', secure: true });

// Client includes the token in a custom header on state-changing requests
// Server verifies the header value matches the cookie value
function verifyCsrf(req: Request) {
  const cookieToken = req.cookies['csrf-token'];
  const headerToken = req.headers['x-csrf-token'];
  if (!cookieToken || cookieToken !== headerToken) {
    throw new Error('CSRF validation failed');
  }
}
```

## Quick Checklist
- [ ] All user-controlled output rendered through auto-escaping templates/widgets — no raw HTML injection
- [ ] Any unavoidable raw-HTML rendering passes through a sanitizer with a strict tag/attribute allowlist
- [ ] CSP configured with no `unsafe-inline`/`unsafe-eval` where feasible
- [ ] Auth/session cookies set `httpOnly`, `Secure`, and `SameSite=Strict`/`Lax`
- [ ] State-changing, cookie-authenticated endpoints protected with CSRF tokens and/or `Origin` checks
- [ ] Sensitive operations require step-up confirmation regardless of session state

## References
- OWASP XSS Prevention Cheat Sheet
- OWASP CSRF Prevention Cheat Sheet
- OWASP Content Security Policy Cheat Sheet
- DOMPurify — https://github.com/cure53/DOMPurify
