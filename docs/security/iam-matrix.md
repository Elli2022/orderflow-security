# IAM Permission Matrix — OrderFlow

**Principle:** Least privilege — each principal receives only the permissions required for its function.  
**Pattern:** One IAM role per Lambda function; no shared "god role".

---

## Human Roles (Break-Glass)

| Role | MFA Required | Permissions | Cannot |
|------|--------------|-------------|--------|
| `security-auditor` | Yes | Read CloudTrail, Security Hub, GuardDuty, read-only DynamoDB | Write any data, modify IAM |
| `platform-admin` | Yes | Terraform deploy, IAM management (with approval) | Direct prod data access without ticket |
| `break-glass-incident` | Yes + approval | Disable compromised credentials, rotate secrets | Standing assignment — time-limited session only |

---

## Service Roles (Lambda)

### order-lambda-role

| Resource | Actions | Condition |
|----------|---------|-----------|
| `dynamodb:orders` | GetItem, PutItem, UpdateItem, Query | `orderId` in application logic only |
| `dynamodb:idempotency_keys` | GetItem, PutItem | Conditional put on idempotency key |
| `events:orderflow-bus` | PutEvents | `source = orderflow.order` only |
| `logs:*` | CreateLogGroup, CreateLogStream, PutLogEvents | Own log group only |
| `kms:orders-key` | Decrypt, GenerateDataKey | Via DynamoDB encryption context |
| `xray:*` | PutTraceSegments | Tracing enabled |

**Explicit Deny:** `payment*`, `inventory*`, `secretsmanager:*` (except none)

---

### payment-lambda-role

| Resource | Actions | Condition |
|----------|---------|-----------|
| `sqs:payment-queue` | ReceiveMessage, DeleteMessage, GetQueueAttributes | — |
| `sqs:payment-dlq` | SendMessage | Only from redrive policy |
| `dynamodb:payments` | GetItem, PutItem, UpdateItem | — |
| `dynamodb:processed_events` | GetItem, PutItem | eventId as idempotency |
| `secretsmanager:payment-provider` | GetSecretValue | Secret ARN scoped |
| `events:orderflow-bus` | PutEvents | `source = orderflow.payment` |
| `kms:payments-key` | Decrypt, GenerateDataKey | — |

**Explicit Deny:** `dynamodb:orders`, `dynamodb:inventory`

---

### inventory-lambda-role

| Resource | Actions |
|----------|---------|
| `sqs:inventory-queue` | ReceiveMessage, DeleteMessage |
| `dynamodb:inventory` | GetItem, UpdateItem (conditional on version) |
| `dynamodb:processed_events` | GetItem, PutItem |
| `events:orderflow-bus` | PutEvents |

---

### orchestrator-lambda-role

| Resource | Actions |
|----------|---------|
| `dynamodb:orders` | GetItem, UpdateItem (status field only) |
| `events:orderflow-bus` | PutEvents |

**Note:** Orchestrator can update order status but cannot read payment details or delete orders.

---

### notification-lambda-role

| Resource | Actions |
|----------|---------|
| `sqs:notification-queue` | ReceiveMessage, DeleteMessage |
| `sns:order-notifications` | Publish |
| `dynamodb:processed_events` | GetItem, PutItem |

**Explicit Deny:** All DynamoDB tables except processed_events

---

## API Gateway

| Component | Auth |
|-----------|------|
| `POST /orders` | Cognito JWT — scope `orders:write` |
| `GET /orders/{id}` | Cognito JWT — scope `orders:read` + ownership check in Lambda |

No API keys in client applications. See [SEC-002](../adr/SEC-002-jwt-authorizer.md).

---

## EventBridge Resource Policy

Only these principals may `events:PutEvents` to `orderflow-bus`:

- `order-lambda-role`
- `payment-lambda-role`
- `inventory-lambda-role`
- `orchestrator-lambda-role`

Event pattern validation enforced via IAM condition keys on `source` and `detail-type`.

---

## Separation of Duties

| Function | Who can do it |
|----------|---------------|
| Deploy infrastructure | `platform-admin` via CI/CD pipeline |
| View audit logs | `security-auditor` |
| Access customer PII in prod | No standing access — break-glass with ticket |
| Rotate secrets | Automated (Secrets Manager) + `break-glass-incident` manual override |

---

## Review Process

- IAM policies defined in Terraform (version controlled)
- Quarterly access review against this matrix
- Any `*` action requires ADR justification
