# Data Classification — OrderFlow

---

## Classification Levels

| Level | Definition | Examples | Handling |
|-------|------------|----------|----------|
| **Public** | Safe to publish | API documentation, architecture diagrams | No restrictions |
| **Internal** | Business use only | Order IDs, SKUs, status, timestamps | Encrypt at rest, access logged |
| **Confidential** | PII / sensitive | Customer name, email, address | KMS encryption, masked in logs, retention limits |
| **Secret** | Credentials | Payment provider API keys, JWT signing keys | Secrets Manager only, never in code/logs |

---

## Data Inventory

| Data Element | Table/Store | Classification | Encrypted | Retention |
|--------------|-------------|----------------|-----------|-----------|
| `orderId` | orders | Internal | Yes (KMS) | 7 years (business) |
| `customerId` | orders | Internal | Yes | 7 years |
| `customerEmail` | orders | Confidential | Yes | 7 years or until RTBF |
| `customerName` | orders | Confidential | Yes | 7 years or until RTBF |
| `items[].sku` | orders | Internal | Yes | 7 years |
| `items[].price` | orders | Internal | Yes | 7 years |
| `paymentRef` | payments | Confidential | Yes | 7 years |
| `stockLevel` | inventory | Internal | Yes | Rolling |
| `idempotencyKey` | idempotency_keys | Internal | Yes | 30 days (TTL) |
| `eventId` | processed_events | Internal | Yes | 30 days (TTL) |
| Payment provider API key | Secrets Manager | Secret | Yes | Rotated every 90 days |
| CloudTrail logs | S3 | Internal | Yes (SSE-KMS) | 1 year |

---

## PII Handling Rules

1. **Never log** `customerEmail`, `customerName`, or `paymentRef` at INFO level
2. **Mask in logs:** `cust***@example.com` if debug required
3. **No PII in** CloudWatch metric dimensions or X-Ray annotations
4. **API responses:** return only data the authenticated user owns (`customerId` match)

---

## Right to Be Forgotten (GDPR Art. 17)

Procedure for erasure request:

1. Verify identity of data subject
2. Locate all records by `customerId` across `orders`, `payments`
3. **Anonymize** (preferred over hard delete for audit): replace PII fields with `REDACTED-{hash}`
4. Retain anonymized order record for legal/accounting obligations if applicable
5. Log erasure action in immutable audit trail (who, when, what customerId)
6. Confirm completion to data subject within 30 days

See [SEC-010 GDPR ADR](../adr/SEC-010-gdpr-data-residency.md).

---

## Data Residency

All data stores and processing in **AWS eu-north-1 (Stockholm)**.  
No cross-region replication in this reference architecture.  
Document exception process if DR requires secondary region (eu-west-1 with DPA).

---

## Data Flow Diagram

```
Client (HTTPS/TLS 1.2+)
    │  JWT — no PII in token claims except sub (customerId)
    ▼
API Gateway
    ▼
Order Lambda — PII in memory only during request
    ▼
DynamoDB (KMS encrypted) — PII at rest
    ▼
Events — NO PII in event payload (only orderId, customerId, status)
    ▼
Downstream workers — payment worker never sees customer email
```

**Key design decision:** Events carry identifiers, not PII. Reduces exposure in logs and queues.
