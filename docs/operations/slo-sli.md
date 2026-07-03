# SLO / SLI — OrderFlow Security & Reliability

---

## Service Level Objectives

| SLO | Target | Measurement Window |
|-----|--------|-------------------|
| API availability | 99.9% | 30 days |
| Order API p95 latency | < 300 ms | 30 days |
| Security: unauthorized access attempts blocked | 100% | Continuous |
| Security: mean time to detect credential anomaly | < 15 min | Per incident |
| Security: DLQ alarm response | < 1 hour | Per incident |
| Audit log completeness | 100% CloudTrail delivery | 30 days |

---

## Security SLIs

| SLI | Source | Alert Threshold |
|-----|--------|-----------------|
| `waf_blocked_requests_rate` | WAF logs | > 1000 blocks / 5 min |
| `api_401_rate` | API Gateway access logs | > 100 / min (possible scan) |
| `guardduty_high_findings` | GuardDuty | >= 1 finding severity >= 7 |
| `dlq_depth` | SQS CloudWatch metric | > 0 for 5 min |
| `root_account_usage` | CloudTrail | any event |
| `cloudtrail_delivery_errors` | CloudTrail metrics | > 0 |

---

## Reliability SLIs

| SLI | Source | Alert Threshold |
|-----|--------|-----------------|
| `order_api_success_rate` | API Gateway 5xx rate | > 0.1% |
| `order_lambda_errors` | Lambda Errors metric | > 10 / 5 min |
| `order_processing_lag` | Time from OrderCreated to OrderConfirmed | p95 < 30s |

---

## Error Budget

At 99.9% availability over 30 days:
- **Allowed downtime:** ~43 minutes/month
- Security incidents that require API shutdown consume error budget — document in post-incident review

---

## Dashboard Panels (CloudWatch)

1. API Gateway: 4xx, 5xx, latency p50/p95/p99
2. WAF: Allowed vs Blocked requests
3. GuardDuty: Finding count by severity
4. Security Hub: Compliance score trend
5. SQS: DLQ depth per queue
6. Lambda: Errors, throttles, duration per function
7. Custom: Orders created / confirmed / failed per hour

---

## Review Cadence

| Review | Frequency |
|--------|-----------|
| SLO burn rate | Weekly |
| Security SLI trends | Daily (automated report) |
| SLO target adjustment | Quarterly |
