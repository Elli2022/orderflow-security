# SEC-009: Incident Response — Credential Rotation Playbook

**Status:** Accepted  
**Date:** 2026-06-29

## Context

Security architecture is incomplete without documented response procedures. Credential leaks are among the most common cloud incidents.

## Decision

Maintain formal incident runbooks for:

- **INC-001:** API credential / JWT compromise
- **INC-002:** DLQ security review (poison messages)

Break-glass access model:
- No standing admin access to production data
- Time-limited `break-glass-incident` role with MFA + ticket approval
- All break-glass usage logged and reviewed within 24h

## Response SLA Targets

| Severity | Detect | Contain | Notify |
|----------|--------|---------|--------|
| Critical (active exfiltration) | 15 min | 30 min | 1 hour internal |
| High (credential leak suspected) | 1 hour | 2 hours | 4 hours internal |
| Medium (WAF spike, no breach) | 4 hours | 8 hours | Next business day |

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| Ad-hoc response | Fails NIS2 incident handling requirements |
| Playbooks only in wiki outside repo | Not version-controlled with architecture |

## Consequences

**Positive:**
- NIS2/GDPR incident readiness
- Interview answer: "Here's our actual runbook"

**Negative:**
- Runbooks must be kept current — assign review date

## Primary Runbook

[INC-001: Credential Leak](../operations/runbooks/INC-001-credential-leak.md)
