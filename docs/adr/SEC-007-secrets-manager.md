# SEC-007: Secrets Manager vs SSM Parameter Store

**Status:** Accepted  
**Date:** 2026-06-29

## Context

Payment Lambda needs credentials for the mock payment provider API. These must not live in environment variables, code, or Terraform state as plaintext.

## Decision

Use **AWS Secrets Manager** for payment provider credentials:

- Automatic rotation every 90 days (Lambda rotation function)
- Encrypted with `alias/orderflow/secrets` CMK
- Access limited to `payment-lambda-role` via resource-scoped IAM

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| SSM Parameter Store (SecureString) | No native rotation; cheaper but less features |
| Lambda env vars | Visible in console, often logged, no rotation |
| HashiCorp Vault | Excellent but operational overhead for portfolio |

## Consequences

**Positive:**
- Rotation story for interviews
- Audit trail via CloudTrail for GetSecretValue
- Industry-standard pattern for API credentials

**Negative:**
- ~$0.40/secret/month + rotation Lambda invocations
- More complex than Parameter Store

## Access Pattern

```python
# handler.py — fetch at cold start, cache in memory for warm invocations
secret = secrets_client.get_secret_value(SecretId=os.environ["PAYMENT_SECRET_ARN"])
```

Never log secret value. ARN in env var is acceptable.
