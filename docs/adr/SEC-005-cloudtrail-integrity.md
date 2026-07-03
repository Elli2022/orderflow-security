# SEC-005: CloudTrail Log File Validation

**Status:** Accepted  
**Date:** 2026-06-29

## Context

Audit logs that can be silently modified are worthless for compliance and incident investigation. Attackers who gain S3 access may delete or alter CloudTrail logs.

## Decision

Enable **CloudTrail log file validation** on all trails.

Additional hardening:
- Dedicated S3 bucket with versioning enabled
- Bucket policy denies `s3:DeleteObject` for all principals except break-glass role
- SSE-KMS encryption with `alias/orderflow/audit` key
- MFA Delete recommended on bucket for production

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| CloudTrail without validation | Cannot cryptographically verify log integrity |
| Logs only in CloudWatch | Not immutable; easier to tamper |
| Third-party SIEM only | Still need tamper-evident source |

## Consequences

**Positive:**
- GDPR/NIS2 audit credibility
- Detects log tampering via digest files
- Standard enterprise security baseline

**Negative:**
- Slight storage overhead for digest files
- S3 costs for long retention

## Verification

```bash
aws cloudtrail validate-logs --trail-arn <trail-arn> --start-time <time>
```
