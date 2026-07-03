# Security Test Results — OrderFlow

**Test date:** 2026-06-29 (template — run after deploy)  
**Environment:** dev (`eu-north-1`)  
**Tester:** Portfolio validation

---

## Test Summary

| Category | Tests | Pass | Fail |
|----------|-------|------|------|
| Access control | 5 | — | — |
| WAF | 3 | — | — |
| Encryption | 4 | — | — |
| Detection | 3 | — | — |
| Logging | 2 | — | — |

*Fill in Pass/Fail after running tests against deployed infrastructure.*

---

## TC-001: Unauthenticated API Access

**Objective:** Verify API rejects requests without valid JWT.

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -X POST "https://API_ID.execute-api.eu-north-1.amazonaws.com/orders" \
  -H "Content-Type: application/json" \
  -d '{"customerId":"test","items":[{"sku":"SKU-001","qty":1}]}'
```

**Expected:** `401 Unauthorized`  
**Result:** _[ ] Pass / [ ] Fail_

---

## TC-002: Cross-User Order Access

**Objective:** User A cannot read User B's order.

**Steps:**
1. Create order as User A (JWT A)
2. GET /orders/{id} with JWT B

**Expected:** `403 Forbidden` or `404 Not Found`  
**Result:** _[ ] Pass / [ ] Fail_

---

## TC-003: WAF Rate Limiting

**Objective:** WAF blocks excessive requests from single IP.

```bash
for i in $(seq 1 3000); do
  curl -s -o /dev/null "https://API_ID/orders" &
done
wait
```

**Expected:** Increasing `403` from WAF after threshold  
**Result:** _[ ] Pass / [ ] Fail_

---

## TC-004: WAF SQL Injection Block

```bash
curl -s -w "%{http_code}" \
  "https://API_ID/orders?id=1' OR '1'='1"
```

**Expected:** `403` (WAF managed rule)  
**Result:** _[ ] Pass / [ ] Fail_

---

## TC-005: DynamoDB Encryption at Rest

**Verification (AWS CLI):**
```bash
aws dynamodb describe-table --table-name orderflow-orders \
  --query 'Table.SSEDescription'
```

**Expected:** `SSEType: KMS`, `KMSMasterKeyArn` present  
**Result:** _[ ] Pass / [ ] Fail_

---

## TC-006: S3 Public Access Block (CloudTrail bucket)

```bash
aws s3api get-public-access-block --bucket orderflow-cloudtrail-ACCOUNT
```

**Expected:** All four blocks enabled  
**Result:** _[ ] Pass / [ ] Fail_

---

## TC-007: GuardDuty Enabled

```bash
aws guardduty list-detectors --region eu-north-1
```

**Expected:** At least one active detector  
**Result:** _[ ] Pass / [ ] Fail_

---

## TC-008: CloudTrail Log File Validation

```bash
aws cloudtrail describe-trails --query 'trailList[0].LogFileValidationEnabled'
```

**Expected:** `true`  
**Result:** _[ ] Pass / [ ] Fail_

---

## TC-009: Lambda Not Publicly Invokable

```bash
aws lambda get-policy --function-name orderflow-order 2>&1 | grep -c "Principal"
```

**Expected:** No public principal (`*`) in resource policy  
**Result:** _[ ] Pass / [ ] Fail_

---

## TC-010: PII Not in Application Logs

**Steps:**
1. Create order with email `test-pii@example.com`
2. Search CloudWatch log group for email string

```bash
aws logs filter-log-events \
  --log-group-name /aws/lambda/orderflow-order \
  --filter-pattern "test-pii@example.com"
```

**Expected:** Zero matches  
**Result:** _[ ] Pass / [ ] Fail_

---

## TC-011: DLQ Alarm Configured

**Verification:** CloudWatch alarm exists for DLQ `ApproximateNumberOfMessagesVisible > 0`  
**Result:** _[ ] Pass / [ ] Fail_

---

## TC-012: IAM Least Privilege Spot Check

**Steps:**
1. Export `order-lambda-role` policy
2. Verify no `Action: "*"` on `Resource: "*"`
3. Verify no access to `payments` table

**Result:** _[ ] Pass / [ ] Fail_

---

## Screenshots to Capture for Portfolio

1. Security Hub compliance score
2. GuardDuty dashboard (no findings = clean)
3. WAF blocked requests graph
4. CloudTrail event for order creation
5. DynamoDB encryption settings
6. IAM policy JSON for order-lambda-role

Save to `docs/security/screenshots/` after testing.
