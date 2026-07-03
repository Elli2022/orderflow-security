# OrderFlow Secure Reference Architecture

**Architecture case study** — not a coding exercise.

Event-driven order platform on AWS designed as a **cloud security reference architecture**: zero trust, least privilege, encryption everywhere, immutable audit trail, and incident response readiness.

> **Target role:** Cloud Security Architect / Security Solutions Architect  
> **Region:** `eu-north-1` (Stockholm) — GDPR data residency  
> **Cert alignment:** AWS Certified Security – Specialty

---

## Problem

E-commerce order flows handle PII and payment data. A naive cloud deployment exposes:

- Over-privileged IAM roles
- Unencrypted data at rest
- No audit trail for compliance (GDPR, NIS2)
- No detection of credential leaks or API abuse

## Solution

OrderFlow demonstrates how to design an event-driven platform where **security controls are architectural decisions**, not afterthoughts.

```
Client → WAF → API Gateway (JWT) → Order Lambda → DynamoDB (KMS)
                              ↓
                        EventBridge → SQS (DLQ) → Workers
                              ↓
                    CloudTrail + GuardDuty + Security Hub
```

## What This Portfolio Proves

| Capability | Evidence |
|------------|----------|
| Threat modeling | [STRIDE analysis](docs/security/threat-model.md) |
| Identity design | [IAM matrix](docs/security/iam-matrix.md) |
| Encryption | [Encryption standard](docs/security/encryption-standard.md) |
| Audit & compliance | [Audit strategy](docs/security/audit-logging-strategy.md), [GDPR/NIS2 mapping](docs/compliance/gdpr-nis2-mapping.md) |
| Incident response | [INC-001 credential leak runbook](docs/operations/runbooks/INC-001-credential-leak.md) |
| Architecture decisions | [10 Security ADRs](docs/adr/) |
| Implementation | [Terraform security baseline](infra/terraform/) |

## Documentation Index

| Document | Purpose |
|----------|---------|
| [Executive Summary](docs/executive-summary.md) | 1-page overview for hiring managers |
| [Security Architecture](docs/architecture/security-architecture.md) | C4 diagrams, data flows, trust boundaries |
| [Threat Model (STRIDE)](docs/security/threat-model.md) | Identified threats and mitigations |
| [Data Classification](docs/security/data-classification.md) | PII handling and retention |
| [IAM Matrix](docs/security/iam-matrix.md) | Least-privilege role design |
| [Encryption Standard](docs/security/encryption-standard.md) | At rest, in transit, key management |
| [Audit & Logging](docs/security/audit-logging-strategy.md) | CloudTrail, log integrity, retention |
| [Security Test Results](docs/security/security-test-results.md) | WAF, GuardDuty, access control tests |
| [SLO/SLI](docs/operations/slo-sli.md) | Operational security metrics |
| [Compliance Mapping](docs/compliance/gdpr-nis2-mapping.md) | GDPR + NIS2 control mapping |

## Security ADRs

| ADR | Decision |
|-----|----------|
| [SEC-001](docs/adr/SEC-001-zero-trust.md) | Zero Trust — no implicit VPC trust |
| [SEC-002](docs/adr/SEC-002-jwt-authorizer.md) | JWT authorizer vs API keys |
| [SEC-003](docs/adr/SEC-003-kms-per-domain.md) | KMS CMK per data domain |
| [SEC-004](docs/adr/SEC-004-waf-strategy.md) | WAF managed + custom rate limits |
| [SEC-005](docs/adr/SEC-005-cloudtrail-integrity.md) | CloudTrail log file validation |
| [SEC-006](docs/adr/SEC-006-guardduty-securityhub.md) | GuardDuty + Security Hub by default |
| [SEC-007](docs/adr/SEC-007-secrets-manager.md) | Secrets Manager vs Parameter Store |
| [SEC-008](docs/adr/SEC-008-vpc-endpoints.md) | VPC endpoints vs NAT for AWS APIs |
| [SEC-009](docs/adr/SEC-009-incident-response.md) | Credential rotation playbook |
| [SEC-010](docs/adr/SEC-010-gdpr-data-residency.md) | EU data residency and RTBF |

## Quick Start (Infrastructure)

```bash
cd infra/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
# terraform apply  # requires AWS credentials
```

## Project Structure

```
orderflow-security/
├── docs/           # 85% of portfolio value — read these first
├── infra/terraform # Security-hardened IaC
├── services/order  # Minimal reference Lambda (not the focus)
├── schemas/events  # Event contracts
└── .github/workflows
```

## Interview Prep — Questions This Project Answers

1. Walk me through what happens when a customer places an order.
2. How do you prevent duplicate orders / replay attacks?
3. What happens if an API credential is leaked?
4. How is PII protected at rest and in transit?
5. What detective controls do you have?
6. How does this map to GDPR / NIS2?
7. What breaks first at 10× traffic from a security perspective?

## Author

Portfolio project for Cloud Security Architect positioning.

**Repository:** https://github.com/Elli2022/orderflow-security  
**Status:** Reference architecture — documentation complete, infrastructure deployable.
