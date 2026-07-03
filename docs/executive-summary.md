# Executive Summary — OrderFlow Secure Reference Architecture

**Version:** 1.0  
**Classification:** Public (portfolio)  
**Region:** AWS eu-north-1 (Stockholm)

---

## Overview

OrderFlow is an event-driven order processing platform designed to demonstrate **production-grade cloud security architecture** on AWS. It is a reference implementation for organizations handling customer PII and payment metadata under GDPR and NIS2 requirements.

## Business Context

Online order systems are high-value targets: they process personal data, interact with payment providers, and face burst traffic during campaigns. Security failures result in regulatory fines, customer churn, and operational downtime.

## Architectural Approach

| Principle | Implementation |
|-----------|----------------|
| Zero Trust | No implicit trust based on network location; every request authenticated and authorized |
| Least Privilege | Per-function IAM roles scoped to specific DynamoDB tables and SQS queues |
| Defense in Depth | WAF → JWT auth → VPC isolation → encryption → detection |
| Auditability | Immutable CloudTrail logs with file validation |
| Detect & Respond | GuardDuty, Security Hub, automated alarms |

## Key Security Controls

1. **Edge:** AWS WAF with OWASP managed rules and rate limiting
2. **Identity:** Cognito JWT authorizer on API Gateway — no long-lived API keys in clients
3. **Network:** Lambdas in private subnets; AWS service access via VPC endpoints
4. **Data:** DynamoDB encrypted with customer-managed KMS keys; PII fields classified and masked in logs
5. **Secrets:** AWS Secrets Manager with rotation policy for payment provider credentials
6. **Detection:** GuardDuty, Security Hub (CIS AWS Foundations), CloudWatch security alarms

## Compliance Alignment

| Framework | Coverage |
|-----------|----------|
| GDPR | Data residency (EU), encryption, audit trail, retention policy, RTBF procedure |
| NIS2 | Incident detection, response runbooks, access control, logging |

See [GDPR/NIS2 mapping](compliance/gdpr-nis2-mapping.md) for control-level detail.

## Risk Summary

| Risk | Residual Level | Primary Control |
|------|----------------|-----------------|
| API abuse / DDoS | Low | WAF rate limiting + API Gateway throttling |
| Credential compromise | Medium-Low | Short-lived JWT, Secrets Manager rotation, GuardDuty |
| Data breach at rest | Low | KMS CMK, least-privilege IAM |
| Insufficient audit trail | Low | CloudTrail with log file validation |
| Message replay | Low | Idempotency keys + processed_events table |

## Deliverables in This Repository

- Full threat model (STRIDE)
- 10 Architecture Decision Records (security-focused)
- IAM permission matrix
- Incident response runbooks
- Terraform security baseline (deployable)
- Minimal reference implementation for demonstration

## Recommended Next Steps (Production Hardening)

- Enable AWS Config rules for continuous compliance
- Add AWS Macie for PII discovery in S3 (if object storage added)
- Multi-account landing zone via AWS Organizations
- Penetration test before production go-live

---

*This document is suitable for sharing with hiring managers and security leadership as a portfolio overview.*
