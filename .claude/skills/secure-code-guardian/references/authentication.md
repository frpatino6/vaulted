# Authentication — Password Hashing & JWT Guide

Detailed guidance for implementing password storage and token-based authentication securely.

## Password Hashing

### Algorithm choice
- Use **argon2id** (preferred) or **bcrypt** (widely supported, acceptable). Never MD5, SHA-1, SHA-256 alone, or unsalted hashes.
- bcrypt: cost factor (salt rounds) of **12+**; re-tune periodically as hardware improves.
- argon2id: tune memory cost, time cost, and parallelism to take ~250-500ms per hash on production hardware.

### Implementation rules
- Always hash on the server — never trust a client-hashed password.
- Use the library's built-in salt generation; never reuse salts across users.
- Compare with the library's constant-time `compare`/`verify` function — never `===` on hashes.
- Enforce a minimum password policy (length ≥ 8, reject top breached-password lists via a service like HaveIBeenPwned's k-anonymity API).
- On login failure, return a generic "invalid credentials" message — never reveal whether the email/username exists.

### Rehashing on login
- Store the algorithm/cost parameters alongside the hash (most libraries embed them).
- On successful login, check if the stored hash was generated with outdated parameters; if so, re-hash with current parameters and update the stored value.

## JWT (JSON Web Tokens)

### Signing and verification
- Use asymmetric signing (RS256/ES256) when the verifier and issuer are different services; use HS256 only when both share a single secret in a trusted boundary.
- Always pass an explicit `algorithms` allowlist to the verify function — never accept `alg: none` or let the token dictate the algorithm (algorithm-confusion attacks).
- Set and validate `iss` (issuer) and `aud` (audience) claims.

### Token lifetime and storage
- Keep access tokens short-lived (minutes to ~24h depending on risk profile); use refresh tokens for longer sessions.
- Store access tokens in memory on the client when possible; store refresh tokens in `httpOnly`, `Secure`, `SameSite=Strict` cookies or platform-secure storage — never `localStorage` (XSS-readable).
- Implement refresh-token rotation: each refresh issues a new refresh token and invalidates the old one.

### Revocation
- JWTs are stateless by design — maintain a server-side blacklist/allowlist (e.g., Redis) for immediate revocation on logout, password change, or compromise.
- Include a `jti` (JWT ID) claim to support targeted revocation.
- Invalidate all sessions on password change or suspected compromise.

### Common pitfalls to avoid
- Trusting unverified claims before signature validation.
- Embedding sensitive data (passwords, full PII, secrets) in the JWT payload — it is base64-encoded, not encrypted, and readable by anyone holding the token.
- Accepting expired tokens due to missing `exp` validation or clock-skew misconfiguration.

## Multi-Factor Authentication (MFA)
- Prefer TOTP (RFC 6238) or WebAuthn/FIDO2 (passkeys, hardware keys) over SMS-based OTP (vulnerable to SIM-swapping).
- Require MFA for privileged roles and sensitive actions (e.g., changing payment details, exporting data).
- Provide secure backup/recovery codes, generated once, hashed at rest, and single-use.

## Session Management
- Regenerate the session identifier / token on privilege change (login, role change) to prevent session fixation.
- Bind sessions to contextual signals (IP range, user agent) where appropriate, and alert on anomalies.
- Provide a "log out of all devices" capability backed by the revocation mechanism above.

## Quick Checklist
- [ ] Passwords hashed with bcrypt (cost ≥ 12) or argon2id, never plaintext/reversible
- [ ] Generic error messages on auth failure (no user enumeration)
- [ ] JWT verified with explicit algorithm allowlist + `iss`/`aud` checks
- [ ] Short-lived access tokens, rotated refresh tokens, server-side revocation list
- [ ] Tokens stored in `httpOnly` cookies or secure platform storage — never `localStorage`
- [ ] MFA available/required for privileged roles via TOTP or WebAuthn
- [ ] Session ID regenerated on login/privilege change

## References
- OWASP Authentication Cheat Sheet
- OWASP JSON Web Token Cheat Sheet
- RFC 6238 (TOTP), RFC 8152 (CBOR/WebAuthn)
