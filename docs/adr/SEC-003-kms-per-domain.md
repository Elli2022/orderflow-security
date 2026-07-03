# SEC-003: KMS CMK Per Data Domain

**Status:** Accepted  
**Date:** 2026-06-29

## Context

DynamoDB supports AWS-owned keys (default), AWS-managed keys, and customer-managed keys (CMK). For a security reference architecture handling PII, key control and auditability matter.

## Decision

Use **separate customer-managed KMS keys (CMK)** per data domain:

- `alias/orderflow/orders` — orders, idempotency, processed_events
- `alias/orderflow/payments` — payments table
- `alias/orderflow/inventory` — inventory table
- `alias/orderflow/audit` — CloudTrail S3, WAF logs
- `alias/orderflow/secrets` — Secrets Manager
- `alias/orderflow/logs` — CloudWatch Logs

Enable automatic annual key rotation on all CMKs.

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| AWS-owned encryption (default) | No key policy control, weak audit story |
| Single CMK for everything | Violates separation of duties; payment key accessible to order Lambda |
| CloudHSM | Cost-prohibitive for portfolio; overkill at this scale |

## Consequences

**Positive:**
- Key policies enforce least privilege per domain
- CloudTrail logs all KMS API calls — key usage audit
- Demonstrates defense-in-depth for interviews

**Negative:**
- ~$1/month per CMK + API costs
- More Terraform complexity

## Key Policy Principle

Payment Lambda can use `payments` key only. Order Lambda cannot decrypt payment data even if application code is compromised (if IAM is correct).
