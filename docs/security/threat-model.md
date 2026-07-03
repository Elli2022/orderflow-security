# Threat Model — OrderFlow (STRIDE)

**Scope:** OrderFlow platform — API, event bus, workers, data stores, secrets, audit pipeline  
**Method:** STRIDE per component  
**Assumption:** Internet-facing API; attackers have no initial insider access

---

## System Boundaries

```
[Internet] ──► [Trust Boundary: Edge] ──► [Trust Boundary: App] ──► [Trust Boundary: Data]
                  WAF, API GW              Lambdas, EventBridge        DynamoDB, Secrets
```

**Assets to protect:**

| Asset | Classification | Impact if compromised |
|-------|----------------|----------------------|
| Customer PII (name, email) | Confidential | GDPR breach, fines |
| Order data | Internal | Business integrity |
| Payment metadata | Confidential | PCI-adjacent risk |
| API credentials / JWT signing keys | Secret | Full API impersonation |
| Audit logs (CloudTrail) | Internal | Compliance failure, blind incident response |

---

## STRIDE Analysis

### 1. API Gateway + WAF (Edge)

| Threat | STRIDE | Scenario | Mitigation | Residual Risk |
|--------|--------|----------|------------|---------------|
| Bot flood / DDoS | Denial of Service | Attacker floods POST /orders | WAF rate limit (2000 req/5min/IP), API GW throttling | Low |
| OWASP Top 10 injection | Tampering | Malformed payloads | WAF managed rule set, request validation schema | Low |
| Stolen bearer token | Spoofing | Replay captured JWT | Short TTL (1h), Cognito token revocation | Medium-Low |
| Enumeration of order IDs | Information Disclosure | Brute-force GET /orders/{id} | UUID order IDs, per-user authorization check | Low |

### 2. Order Lambda (Application)

| Threat | STRIDE | Scenario | Mitigation | Residual Risk |
|--------|--------|----------|------------|---------------|
| Over-privileged execution role | Elevation of Privilege | Compromised Lambda exfiltrates all tables | IAM scoped to `orders` table only — see [IAM matrix](iam-matrix.md) | Low |
| Log injection of PII | Information Disclosure | Error handler logs full request body | Structured logging with PII redaction | Low |
| Duplicate order submission | Repudiation | Client retries create double charge | Idempotency-Key header + conditional DynamoDB write | Low |

### 3. EventBridge + SQS (Messaging)

| Threat | STRIDE | Scenario | Mitigation | Residual Risk |
|--------|--------|----------|------------|---------------|
| Unauthorized event publish | Spoofing | Attacker publishes fake PaymentCompleted | EventBridge IAM resource policies — only authorized Lambdas publish | Low |
| Message replay | Tampering | Old event reprocessed | `processed_events` idempotency table with eventId PK | Low |
| Poison message loop | Denial of Service | Malformed message blocks queue | DLQ after 3 receives, alarm on DLQ depth | Low |

### 4. DynamoDB (Data)

| Threat | STRIDE | Scenario | Mitigation | Residual Risk |
|--------|--------|----------|------------|---------------|
| Data exfiltration via stolen IAM | Information Disclosure | Leaked Lambda credentials | Least privilege + GuardDuty IAM anomaly detection | Medium-Low |
| Unencrypted data at rest | Information Disclosure | Disk/snapshot access | KMS CMK encryption enabled (AWS-owned key insufficient for portfolio story) | Low |
| Unauthorized delete | Tampering | Malicious admin wipes orders | Point-in-time recovery enabled; delete restricted to break-glass role | Low |

### 5. Secrets Manager

| Threat | STRIDE | Scenario | Mitigation | Residual Risk |
|--------|--------|----------|------------|---------------|
| Long-lived API key to payment provider | Spoofing | Key in source code or env var | Secrets Manager + rotation schedule | Low |
| Secret read by wrong Lambda | Elevation of Privilege | payment-lambda reads order secrets | Resource-scoped `secretsmanager:GetSecretValue` per secret ARN | Low |

### 6. CloudTrail + Audit Pipeline

| Threat | STRIDE | Scenario | Mitigation | Residual Risk |
|--------|--------|----------|------------|---------------|
| Attacker deletes audit logs | Repudiation | Disable trail or delete S3 logs | S3 bucket policy deny delete except break-glass; MFA delete on bucket | Low |
| Log tampering | Tampering | Modify log files in S3 | CloudTrail log file validation enabled | Low |

---

## Attack Trees (Simplified)

### Attack: Steal customer order data

```
Steal order data
├── Compromise client JWT → Mitigated by short TTL + HTTPS only
├── Exploit API vulnerability → Mitigated by WAF + input validation
├── Compromise Lambda IAM → Mitigated by least privilege (orders table only)
├── Direct DynamoDB access → Mitigated by no public access, IAM only
└── Insider with admin role → Mitigated by CloudTrail + separation of duties
```

### Attack: Disrupt order processing

```
Disrupt orders
├── DDoS API → WAF rate limit + API GW throttling
├── Flood SQS → DLQ + concurrency limits
└── Delete DynamoDB table → PITR + IAM deny delete for app roles
```

---

## Out of Scope (Documented)

- Physical datacenter security (AWS responsibility under shared model)
- Client-side malware on end-user devices
- Supply chain attacks on npm/pypi dependencies (noted for SBOM in production)

---

## Review Cadence

- **Quarterly** threat model review
- **After** any architecture change (new integration, new data class)
- **After** any security incident

See [SEC-009 incident response ADR](../adr/SEC-009-incident-response.md).
