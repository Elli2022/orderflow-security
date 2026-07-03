# Security Architecture — OrderFlow

---

## C4 Level 1: System Context

```mermaid
flowchart LR
    Customer[Customer / API Client]
    OrderFlow[OrderFlow Platform]
    Payment[Payment Provider - Mock]
    SecOps[Security Operations]
    Regulator[Compliance / Audit]

    Customer -->|HTTPS + JWT| OrderFlow
    OrderFlow -->|TLS API| Payment
    SecOps -->|Monitors| OrderFlow
    Regulator -->|Audit reports| OrderFlow
```

**Trust boundaries:** Internet (untrusted) → Edge (semi-trusted) → Application (trusted compute) → Data (highly protected)

---

## C4 Level 2: Container Diagram

```mermaid
flowchart TB
    subgraph Edge["Edge Security Zone"]
        WAF[AWS WAF]
        APIGW[API Gateway HTTP API]
        COG[Cognito User Pool]
    end

    subgraph App["Application Zone - Private VPC"]
        OL[Order Lambda]
        PL[Payment Lambda]
        IL[Inventory Lambda]
        ORCH[Orchestrator Lambda]
        NL[Notification Lambda]
    end

    subgraph Messaging["Event Layer"]
        EB[EventBridge Bus]
        PQ[SQS Payment + DLQ]
        IQ[SQS Inventory + DLQ]
        NQ[SQS Notification + DLQ]
    end

    subgraph Data["Data Zone - Encrypted"]
        DDB_O[(Orders)]
        DDB_P[(Payments)]
        DDB_I[(Inventory)]
        SM[Secrets Manager]
    end

    subgraph Detect["Detection Zone"]
        CT[CloudTrail]
        GD[GuardDuty]
        SH[Security Hub]
        CW[CloudWatch Alarms]
    end

    Client[Client] --> WAF --> APIGW
    COG -.->|JWT| APIGW
    APIGW --> OL
    OL --> DDB_O
    OL --> EB
    EB --> PQ --> PL
    EB --> IQ --> IL
    EB --> ORCH
    EB --> NQ --> NL
    PL --> DDB_P
    PL --> SM
    IL --> DDB_I
    OL & PL & IL & ORCH & NL --> CT
    GD & SH --> CW
```

---

## Security Data Flow — Happy Path

```
1. Client authenticates with Cognito → receives JWT (1h TTL)
2. POST /orders with Authorization: Bearer <jwt>
3. WAF inspects request (rate limit, OWASP rules)
4. API Gateway validates JWT signature and scope
5. Order Lambda:
   a. Validates Idempotency-Key
   b. Writes order (PENDING) to DynamoDB — KMS encrypted
   c. Publishes OrderCreated event (no PII in payload)
6. Payment worker processes async — reads secret from Secrets Manager
7. CloudTrail records all DynamoDB data events
```

---

## Security Data Flow — Credential Leak Scenario

```
1. GuardDuty detects anomalous IAM/API activity
2. Alarm fires → SNS → SecOps
3. Break-glass role disables compromised credential
4. Secrets Manager force-rotation triggered
5. CloudTrail queried for blast radius (last 24h)
6. Incident documented per INC-001 runbook
```

---

## Network Architecture

| Component | Subnet | Internet Access |
|-----------|--------|-----------------|
| Lambda functions | Private | Via VPC endpoints only |
| VPC endpoints | Private | DynamoDB, SQS, Secrets Manager, Logs, EventBridge |
| API Gateway | AWS managed | Public (protected by WAF) |
| NAT Gateway | Not required | Endpoints eliminate NAT for AWS APIs |

See [SEC-008 VPC endpoints ADR](../adr/SEC-008-vpc-endpoints.md).

---

## Defense in Depth Layers

| Layer | Control |
|-------|---------|
| 1. Perimeter | WAF, Shield Standard, rate limiting |
| 2. Identity | Cognito JWT, IAM roles, no long-lived keys |
| 3. Network | Private subnets, VPC endpoints, security groups |
| 4. Application | Input validation, idempotency, PII redaction |
| 5. Data | KMS encryption, least-privilege table access |
| 6. Detection | GuardDuty, Security Hub, CloudTrail, alarms |
| 7. Response | Runbooks, break-glass, secret rotation |

---

## Related Documents

- [Threat Model](../security/threat-model.md)
- [IAM Matrix](../security/iam-matrix.md)
- [Encryption Standard](../security/encryption-standard.md)
- [All Security ADRs](../adr/)
