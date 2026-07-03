# GDPR & NIS2 Compliance Mapping — OrderFlow

**Disclaimer:** This is a portfolio reference mapping, not legal advice. Production deployments require DPO/legal review.

---

## GDPR Mapping

| Article | Requirement | OrderFlow Control | Evidence |
|---------|-------------|-------------------|----------|
| Art. 5(1)(f) | Integrity and confidentiality | Encryption, access control, audit | [Encryption standard](../security/encryption-standard.md) |
| Art. 17 | Right to erasure | RTBF procedure in data classification | [Data classification](../security/data-classification.md) |
| Art. 25 | Data protection by design | Security ADRs, PII not in events | [SEC-010 ADR](../adr/SEC-010-gdpr-data-residency.md) |
| Art. 30 | Records of processing | Data inventory in classification doc | [Data classification](../security/data-classification.md) |
| Art. 32 | Security of processing | KMS, IAM, WAF, monitoring | [Security architecture](../architecture/security-architecture.md) |
| Art. 33 | Breach notification (72h) | Incident runbooks, GuardDuty detection | [INC-001 runbook](../operations/runbooks/INC-001-credential-leak.md) |
| Art. 35 | DPIA (if high risk) | Threat model serves as DPIA input | [Threat model](../security/threat-model.md) |

### Data Residency (Art. 44+)

- All processing in **eu-north-1** (EU)
- No transfers to third countries in reference architecture
- AWS DPA in place for production (standard AWS artifact)

---

## NIS2 Mapping (High Level)

NIS2 applies to essential/important entities. Mapping demonstrates readiness for regulated sectors.

| NIS2 Area | Requirement | OrderFlow Control |
|-----------|-------------|-------------------|
| Risk management | Identify and assess risks | STRIDE threat model |
| Incident handling | Detect, respond, report | GuardDuty, runbooks, CloudTrail |
| Business continuity | Backup and recovery | DynamoDB PITR, DLQ replay |
| Supply chain security | Third-party risk | AWS shared responsibility documented |
| Policies on cryptography | Encrypt sensitive data | KMS CMK standard |
| Access control | Least privilege | IAM matrix |
| Asset management | Know what you protect | Data classification inventory |

---

## AWS Shared Responsibility

| Layer | AWS | Customer (OrderFlow) |
|-------|-----|----------------------|
| Physical security | ✅ | — |
| Hypervisor / host | ✅ | — |
| Network infrastructure | ✅ | — |
| IAM configuration | — | ✅ |
| Data encryption keys | — | ✅ |
| Application security | — | ✅ |
| WAF rules tuning | — | ✅ |
| Incident response execution | Shared | ✅ |

---

## Compliance Gaps (Honest Assessment for Portfolio)

| Gap | Mitigation Path |
|-----|-----------------|
| No formal DPIA document | Threat model + data classification as input |
| No AWS Config continuous compliance | Add Config rules in production phase |
| No penetration test report | Schedule before production |
| No SBOM for dependencies | Add `pip audit` / Dependabot in CI |

Documenting gaps shows maturity — architects know what's not done yet.

---

## Audit Evidence Package

For compliance audits, provide:

1. Architecture diagrams (this repo)
2. IAM matrix + Terraform IAM policies
3. CloudTrail configuration screenshot/export
4. Encryption configuration per table
5. Incident response runbooks
6. Data retention configuration
7. ADRs showing conscious security decisions
