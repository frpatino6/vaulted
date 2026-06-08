# OWASP Top 10 — Prevention Guide

Reference for preventing the OWASP Top 10 (2021) vulnerability classes when implementing or reviewing application code.

## A01: Broken Access Control
- Enforce authorization checks on every request — never rely on hidden UI elements or client-side checks alone.
- Default deny: require an explicit grant for each role/resource combination.
- Validate object ownership server-side (e.g., a user can only fetch/modify their own records) to prevent IDOR (Insecure Direct Object Reference).
- Scope queries by tenant/owner ID at the data-access layer, not just in controllers.

## A02: Cryptographic Failures
- Classify data (PII, financial, health) and encrypt sensitive fields at rest (AES-256) and in transit (TLS 1.2+).
- Never invent custom crypto — use vetted libraries (`crypto`, `libsodium`, `bcrypt`/`argon2`).
- Avoid weak/deprecated algorithms: MD5, SHA-1, DES, RC4, ECB mode.
- Manage keys via environment variables or a secrets manager — never commit them to source.

## A03: Injection
- Use parameterized queries / prepared statements / ORM query builders for all database access — never string-concatenate user input into queries.
- Validate and allowlist input formats (type, length, range) before use.
- Escape output appropriately for its context (SQL, shell, HTML, LDAP).
- Avoid `eval`, dynamic `exec`, and OS shell calls built from user input.

## A04: Insecure Design
- Threat-model new features before writing code: identify trust boundaries, attacker goals, and abuse cases.
- Apply secure design patterns: least privilege, fail-safe defaults, defense in depth.
- Add explicit limits (rate limits, payload size caps, pagination) at design time, not as an afterthought.

## A05: Security Misconfiguration
- Disable verbose error messages and stack traces in production responses.
- Remove default accounts, sample apps, and unused features/endpoints.
- Keep frameworks, dependencies, and base images patched and pinned.
- Apply security headers (see `security-headers.md`) and a hardened CORS policy.

## A06: Vulnerable and Outdated Components
- Run dependency audits regularly (`npm audit`, `trivy`, `osv-scanner`) and address High/Critical findings promptly.
- Pin dependency versions and review changelogs before upgrading security-relevant packages.
- Remove unused dependencies to shrink the attack surface.

## A07: Identification and Authentication Failures
- Hash passwords with bcrypt/argon2 (see `authentication.md`); never store plaintext or reversible encryption.
- Enforce MFA for privileged roles and sensitive operations.
- Implement account lockout / rate limiting on login and password-reset endpoints.
- Invalidate sessions/tokens on logout, password change, and privilege change; rotate refresh tokens.

## A08: Software and Data Integrity Failures
- Verify integrity of dependencies and CI/CD artifacts (lockfiles, checksums, signed packages).
- Avoid deserializing untrusted data; if unavoidable, use safe formats (JSON with schema validation) instead of native serialization.
- Protect CI/CD pipelines: restrict who can modify build scripts and secrets.

## A09: Security Logging and Monitoring Failures
- Log security-relevant events: authentication attempts (success/failure), authorization denials, input-validation failures, privilege changes.
- Never log secrets, passwords, tokens, or full PII — mask or redact sensitive fields.
- Ensure logs are tamper-evident (append-only / immutable storage) and retained per compliance requirements.
- Alert on anomalies: repeated failed logins, privilege escalation attempts, unusual data access volume.

## A10: Server-Side Request Forgery (SSRF)
- Validate and allowlist destination hosts/IPs before making server-side HTTP requests based on user input.
- Block requests to internal/private IP ranges (RFC1918, link-local, cloud metadata endpoints) unless explicitly required.
- Disable unused URL schemes (`file://`, `gopher://`, `dict://`) in HTTP client libraries.

## Quick Checklist
- [ ] All queries parameterized — no string-built SQL/NoSQL
- [ ] Authorization enforced server-side, scoped by tenant/owner
- [ ] Secrets in env vars / secret manager, never in source
- [ ] Passwords hashed with bcrypt/argon2, MFA on sensitive roles
- [ ] Dependencies audited and patched
- [ ] Security headers and CORS allowlist configured
- [ ] Security events logged without leaking sensitive data
- [ ] Outbound requests to user-supplied URLs validated/allowlisted

## References
- OWASP Top 10:2021 — https://owasp.org/Top10/
- CWE Top 25 Most Dangerous Software Weaknesses
- OWASP Cheat Sheet Series
