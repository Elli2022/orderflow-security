# SEC-004: WAF Strategy — Managed Rules + Rate Limiting

**Status:** Accepted  
**Date:** 2026-06-29

## Context

API Gateway alone provides throttling but not OWASP-layer protection or IP-based rate limiting at the edge.

## Decision

Deploy **AWS WAF** in front of API Gateway with:

1. **AWSManagedRulesCommonRuleSet** — OWASP Top 10
2. **AWSManagedRulesKnownBadInputsRuleSet** — known malicious patterns
3. **Rate-based rule** — block IP exceeding 2000 requests per 5 minutes
4. **WAF logging** to S3 (KMS encrypted, 90-day retention)

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| API Gateway throttling only | No OWASP protection, per-API not per-IP |
| CloudFront + WAF | Valid for production; added complexity for MVP |
| Third-party WAF (Cloudflare) | Good option but AWS-native preferred for cert alignment |

## Consequences

**Positive:**
- Blocks common attacks before they reach Lambda (cost + security)
- WAF logs feed security investigations
- Rate limit protects against accidental and malicious floods

**Negative:**
- WAF cost: ~$5/month base + $0.60/million requests
- Managed rules can false-positive — tune in production

## Tuning Note

If legitimate traffic triggers blocks, create count-mode overrides before switching to block.
