# SEC-008: VPC Endpoints vs NAT Gateway

**Status:** Accepted  
**Date:** 2026-06-29

## Context

Lambdas in private subnets need to call AWS services (DynamoDB, SQS, Secrets Manager, CloudWatch Logs, EventBridge). Options: NAT Gateway (route to public internet) or VPC Interface/Gateway Endpoints (stay on AWS network).

## Decision

Use **VPC endpoints** for all required AWS services:

- **Gateway endpoint:** DynamoDB, S3 (CloudTrail bucket)
- **Interface endpoints:** SQS, Secrets Manager, CloudWatch Logs, EventBridge, KMS

**No NAT Gateway** in reference architecture.

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| NAT Gateway | ~$32/month + data processing; traffic exits to internet |
| Public Lambda (no VPC) | Simpler but weaker isolation |
| Single NAT for cost | Single point of failure; still routes via internet |

## Consequences

**Positive:**
- Traffic to AWS APIs never leaves AWS network
- No NAT cost
- Stronger Zero Trust network story

**Negative:**
- Interface endpoints: ~$7/month each + data charges
- More Terraform resources
- DNS configuration required for interface endpoints

## Cost Note

6 interface endpoints ≈ $42/month. For dev portfolio, can reduce to critical endpoints only and document trade-off.
