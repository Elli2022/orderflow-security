# INC-002: DLQ Security Review — Poison Message

**Severity:** MEDIUM  
**Owner:** Security Operations  
**Last reviewed:** 2026-06-29

---

## Triggers

- CloudWatch alarm: DLQ `ApproximateNumberOfMessagesVisible > 0`
- Lambda error rate spike on payment/inventory/notification workers
- GuardDuty finding related to unusual Lambda behavior

---

## Context

Messages in Dead Letter Queues may indicate:
1. **Benign:** Downstream service outage (retry exhausted)
2. **Security concern:** Malformed/crafted message attempting injection or logic abuse
3. **Data issue:** Unexpected payload from compromised publisher

Treat all DLQ messages as **untrusted input** during investigation.

---

## Response Steps

### 1. CONTAIN

- [ ] Do **not** immediately replay messages to main queue
- [ ] Note which queue: `payment-dlq`, `inventory-dlq`, or `notification-dlq`
- [ ] Check if DLQ depth is growing (active attack) vs static (past failure)

### 2. INSPECT (safely)

- [ ] Receive message with **no Lambda processing** — use SQS console or CLI peek:
  ```bash
  aws sqs receive-message --queue-url DLQ_URL --max-number-of-messages 1
  ```
- [ ] Analyze payload structure against schema: `schemas/events/`
- [ ] Check `source` and `detail-type` in EventBridge envelope
- [ ] Verify publisher principal in CloudTrail `PutEvents` logs

### 3. CLASSIFY

| Finding | Classification | Action |
|---------|----------------|--------|
| Valid event, transient failure | Operational | Fix root cause, replay via [dlq-replay.md](dlq-replay.md) |
| Schema violation / unexpected fields | Security | Block publisher IAM, investigate compromise |
| PII in event payload | Compliance | Violates SEC-010, fix publisher, redact logs |
| Unknown `source` in event | Security | Revoke unauthorized PutEvents principal |

### 4. REMEDIATE

- [ ] If security issue: follow [INC-001](INC-001-credential-leak.md) if IAM compromise suspected
- [ ] If operational: fix worker bug, deploy, replay messages
- [ ] Purge malicious messages (document each message ID purged)

### 5. PREVENT

- [ ] Tighten EventBridge IAM resource policy
- [ ] Add JSON Schema validation on consumer (reject unknown fields)
- [ ] Review if message size limits are configured on SQS

---

## Security Principle

**Never replay DLQ messages to production without inspection.**  
Replay script must log each message ID and operator identity.

See [dlq-replay.md](dlq-replay.md).
