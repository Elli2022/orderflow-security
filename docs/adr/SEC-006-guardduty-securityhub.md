# SEC-006: GuardDuty + Security Hub Enabled by Default

**Status:** Accepted  
**Date:** 2026-06-29

## Context

Preventive controls (IAM, WAF, encryption) are insufficient without detective controls. Security teams need centralized visibility into misconfigurations and threats.

## Decision

Enable by default in all environments:

- **Amazon GuardDuty** — threat detection (anomalous IAM, crypto mining, reconnaissance)
- **AWS Security Hub** — CIS AWS Foundations Benchmark v1.4.0
- **Findings → SNS** → security ops topic for HIGH/CRITICAL severity

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| CloudTrail only | Detection, not intelligent threat identification |
| Third-party SIEM only | Higher cost; AWS-native sufficient for portfolio |
| GuardDuty without Security Hub | Misses compliance posture scoring |

## Consequences

**Positive:**
- Detects credential compromise scenarios for INC-001
- Security Hub score is portfolio screenshot gold
- CIS benchmark maps to audit checklists

**Negative:**
- GuardDuty ~$4-30/month depending on volume
- Initial Security Hub findings require remediation sprint

## Portfolio Tip

Screenshot Security Hub compliance score before and after remediation — shows improvement narrative.
