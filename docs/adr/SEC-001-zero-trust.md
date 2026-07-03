# SEC-001: Zero Trust — No Implicit VPC Trust

**Status:** Accepted  
**Date:** 2026-06-29  
**Deciders:** Cloud Security Architect (portfolio)

## Context

Traditional network security assumes resources inside a VPC are trusted ("castle and moat"). In cloud environments, compromised workloads inside a VPC can lateral-move to other resources.

## Decision

Adopt **Zero Trust** principles for OrderFlow:

- Authenticate and authorize every API request (JWT)
- Scope IAM permissions per function — no broad VPC-based trust
- Use VPC for **network isolation**, not as proof of trust
- Enable VPC endpoints to avoid exposing traffic to public internet

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| Public Lambda (no VPC) | Simpler but weaker network isolation story |
| Security groups as sole control | SGs are necessary but insufficient alone |
| mTLS between all services | Over-engineered for serverless at this scale |

## Consequences

**Positive:**
- Aligns with NIS2 and modern security frameworks
- Strong portfolio narrative for architect interviews

**Negative:**
- VPC-attached Lambdas have cold start penalty (~1-3s)
- VPC endpoints have hourly cost (~$7/endpoint/month)

## Compliance

- NIS2: access control and network segmentation
- GDPR Art. 32: appropriate technical measures
