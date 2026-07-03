# Audit & Logging Strategy — OrderFlow

---

## Objectives

1. **Detect** unauthorized access and configuration changes
2. **Investigate** security incidents with tamper-evident logs
3. **Demonstrate** compliance with GDPR and NIS2 audit requirements
4. **Retain** logs per policy without unbounded cost

---

## Log Sources

| Source | What It Captures | Destination | Retention |
|--------|------------------|-------------|-----------|
| CloudTrail (management) | IAM changes, API calls, console login | S3 (KMS encrypted) | 1 year |
| CloudTrail (data events) | DynamoDB GetItem/PutItem/Query | S3 (KMS encrypted) | 90 days |
| API Gateway access logs | Request ID, IP, status, latency — **no PII** | CloudWatch Logs | 30 days |
| Lambda application logs | Structured JSON, PII-redacted | CloudWatch Logs (KMS) | 30 days |
| VPC Flow Logs | Accepted/rejected traffic metadata | CloudWatch Logs | 14 days |
| WAF logs | Blocked/allowed requests | S3 | 90 days |
| GuardDuty | Threat findings | Security Hub + SNS | 90 days |
| Security Hub | Aggregated compliance findings | Security Hub | Continuous |

---

## CloudTrail Configuration

| Setting | Value | Rationale |
|---------|-------|-----------|
| Multi-region trail | Yes | Detect activity in any region |
| Log file validation | **Enabled** | Tamper detection — SEC-005 |
| S3 bucket | Dedicated, no public access | Isolation |
| S3 bucket policy | Deny `s3:DeleteObject` except break-glass | Anti-tampering |
| KMS encryption | CMK `alias/orderflow/audit` | Key control |
| Data events | DynamoDB tables (orders, payments) | PII access audit |

---

## Application Logging Standard

```json
{
  "timestamp": "2026-06-29T10:00:00Z",
  "level": "INFO",
  "service": "order-lambda",
  "correlationId": "corr-abc123",
  "orderId": "ord_xyz",
  "customerId": "cust_456",
  "action": "order_created",
  "message": "Order created successfully"
}
```

**Prohibited fields in logs:** `customerEmail`, `customerName`, `paymentRef`, raw request body.

---

## Security Alarms

| Alarm | Condition | Action |
|-------|-----------|--------|
| `dlq-messages-visible` | DLQ depth > 0 for 5 min | SNS → security ops |
| `guardduty-high-finding` | Severity >= 7 | SNS → security ops |
| `unauthorized-api-calls` | CloudTrail `AccessDenied` spike | SNS → security ops |
| `root-account-usage` | Any root API call | SNS → immediate page |
| `waf-block-spike` | Blocked requests > 1000/5min | SNS → security ops |

---

## Log Integrity

1. CloudTrail log file validation enabled
2. S3 versioning on audit bucket
3. S3 Object Lock (Governance mode) — recommended for production
4. No application role has `s3:DeleteObject` on audit bucket

---

## Incident Investigation Query Examples

**CloudTrail — who accessed order data?**
```
eventSource = dynamodb.amazonaws.com
eventName IN (GetItem, Query, Scan)
requestParameters.tableName = orderflow-orders
```

**API Gateway — failed auth spike?**
```
filter @message like /401/
| stats count() by bin(5m)
```

---

## Review Cadence

| Activity | Frequency |
|----------|-----------|
| Review GuardDuty findings | Daily (automated); weekly (human) |
| Review Security Hub compliance score | Weekly |
| Audit IAM vs permission matrix | Quarterly |
| Log retention policy review | Annually |

See runbook [INC-001](operations/runbooks/INC-001-credential-leak.md) for investigation procedures.
