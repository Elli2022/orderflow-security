# SEC-002: JWT Authorizer (Cognito) vs API Keys

**Status:** Accepted  
**Date:** 2026-06-29

## Context

The Order API must authenticate clients. Long-lived API keys in mobile/web apps are frequently leaked via source code, logs, or client-side storage.

## Decision

Use **Amazon Cognito User Pool** with **JWT authorizer** on API Gateway:

- Access tokens TTL: 1 hour
- Refresh tokens: 30 days (stored securely client-side)
- Scopes: `orders:read`, `orders:write`
- Public client with PKCE (no client secret in SPA/mobile)

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| API keys in header | Long-lived, hard to rotate, leak-prone |
| Lambda authorizer with custom tokens | More code to maintain and secure |
| Mutual TLS (client certs) | Poor UX for consumer e-commerce |
| AWS IAM SigV4 from client | Not suitable for end-user clients |

## Consequences

**Positive:**
- Short-lived credentials limit blast radius of leak
- Cognito handles lockout, MFA (can enable), token revocation
- Standard OIDC — portable pattern

**Negative:**
- Cognito adds complexity for demo/testing
- Requires token refresh flow in client

## Incident Reference

See [INC-001](../operations/runbooks/INC-001-credential-leak.md) — JWT compromise procedure.
