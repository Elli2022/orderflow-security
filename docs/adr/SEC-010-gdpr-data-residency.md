# SEC-010: GDPR Data Residency and RTBF

**Status:** Accepted  
**Date:** 2026-06-29

## Context

OrderFlow processes EU customer PII (name, email). GDPR requires lawful processing, data minimization, and rights including erasure (Art. 17).

## Decision

1. **Data residency:** All resources in `eu-north-1` (Stockholm) only
2. **Data minimization:** No PII in event payloads — only `orderId`, `customerId`, `status`
3. **RTBF procedure:** Anonymize PII fields (not hard delete) to preserve audit trail
4. **Retention:** Idempotency/processed_events TTL 30 days; orders per business policy with documented legal basis
5. **DPA:** AWS GDPR DPA required before production

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| us-east-1 deployment | GDPR transfer complexity for EU customers |
| Hard delete on RTBF | Breaks accounting audit trail |
| PII in SQS messages | Expands exposure surface in logs |

## Consequences

**Positive:**
- Clear GDPR story for EU employers (bank, health, gov)
- Event design reduces compliance scope

**Negative:**
- Single-region = no cross-region DR without additional DPA analysis
- Anonymization requires careful implementation

## RTBF Implementation

See [Data Classification — RTBF procedure](../security/data-classification.md#right-to-be-forgotten-gdpr-art-17).
