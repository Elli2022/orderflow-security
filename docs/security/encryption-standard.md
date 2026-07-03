# Encryption Standard — OrderFlow

---

## Requirements

| State | Requirement | Standard |
|-------|-------------|----------|
| In transit | TLS 1.2 minimum | All client ↔ API, all AWS API calls |
| At rest | AES-256 | All DynamoDB, S3, Secrets Manager, CloudWatch Logs |
| Key management | Customer-managed keys (CMK) | Per data domain — see SEC-003 |
| Key rotation | Automatic annual | AWS KMS automatic key rotation enabled |

---

## In Transit

| Path | Encryption |
|------|------------|
| Client → API Gateway | HTTPS (TLS 1.2+), HSTS recommended at CDN if added |
| API Gateway → Lambda | AWS internal TLS |
| Lambda → DynamoDB | HTTPS via AWS SDK (TLS 1.2+) |
| Lambda → SQS/EventBridge | HTTPS via AWS SDK |
| VPC endpoints | TLS inside AWS network — traffic does not traverse public internet |

**Prohibited:** HTTP (non-TLS) endpoints, self-signed certificates in production.

---

## At Rest

| Resource | Encryption | Key |
|----------|------------|-----|
| DynamoDB `orders` | SSE-KMS | `alias/orderflow/orders` |
| DynamoDB `payments` | SSE-KMS | `alias/orderflow/payments` |
| DynamoDB `inventory` | SSE-KMS | `alias/orderflow/inventory` |
| DynamoDB `idempotency_keys` | SSE-KMS | `alias/orderflow/orders` |
| DynamoDB `processed_events` | SSE-KMS | `alias/orderflow/orders` |
| CloudTrail S3 bucket | SSE-KMS | `alias/orderflow/audit` |
| Secrets Manager | KMS | `alias/orderflow/secrets` |
| CloudWatch Logs | KMS | `alias/orderflow/logs` |

**AWS-managed keys (aws/dynamodb) are not used** — CMK required for audit story and key policy control.

---

## KMS Key Policies

Each CMK key policy grants:

- **Use:** Only the specific Lambda role(s) for that domain
- **Admin:** `platform-admin` role only (not application roles)
- **Deny:** `kms:ScheduleKeyDeletion` except break-glass with MFA

```json
{
  "Sid": "AllowOrderLambdaUse",
  "Effect": "Allow",
  "Principal": { "AWS": "arn:aws:iam::ACCOUNT:role/orderflow-order-lambda" },
  "Action": ["kms:Decrypt", "kms:GenerateDataKey"],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "kms:ViaService": "dynamodb.eu-north-1.amazonaws.com"
    }
  }
}
```

---

## Secrets

| Secret | Storage | Rotation |
|--------|---------|----------|
| Payment provider API key | Secrets Manager | 90 days automatic |
| Cognito app client secret | Not used (public client + PKCE) | N/A |

Never store secrets in:
- Lambda environment variables (plaintext)
- Terraform state (use SSM/Secrets Manager data sources)
- Git repository

---

## Certificate Management

- API Gateway manages edge certificates via AWS Certificate Manager (ACM)
- Internal service mesh not required at this scale
- Certificate expiry monitored via ACM automatic renewal

---

## Compliance Mapping

| Control | Implementation |
|---------|----------------|
| GDPR Art. 32 | Encryption of personal data at rest and in transit |
| NIS2 Art. 21 | Cryptographic controls for data protection |

See [gdpr-nis2-mapping.md](../compliance/gdpr-nis2-mapping.md).
