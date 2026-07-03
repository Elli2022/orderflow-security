# DLQ Replay Procedure

**Prerequisite:** Complete [INC-002 security review](INC-002-dlq-security-review.md) before replay.

---

## When to Replay

- Root cause fixed (bug deploy, service restored)
- Messages classified as **operational failure**, not security threat
- Approval from on-call engineer documented in ticket

---

## Replay Script

```bash
#!/usr/bin/env bash
# scripts/dlq-replay.sh
set -euo pipefail

DLQ_URL="${1:?DLQ queue URL required}"
MAIN_QUEUE_URL="${2:?Main queue URL required}"
MAX_MESSAGES="${3:-10}"

echo "Replaying up to ${MAX_MESSAGES} messages from DLQ to main queue"
echo "Operator: $(aws sts get-caller-identity --query Arn --output text)"
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

for i in $(seq 1 "$MAX_MESSAGES"); do
  MSG=$(aws sqs receive-message --queue-url "$DLQ_URL" --max-number-of-messages 1)
  BODY=$(echo "$MSG" | jq -r '.Messages[0].Body // empty')
  RECEIPT=$(echo "$MSG" | jq -r '.Messages[0].ReceiptHandle // empty')

  if [ -z "$BODY" ]; then
    echo "No more messages in DLQ"
    break
  fi

  echo "Replaying message $i..."
  aws sqs send-message --queue-url "$MAIN_QUEUE_URL" --message-body "$BODY"
  aws sqs delete-message --queue-url "$DLQ_URL" --receipt-handle "$RECEIPT"
done

echo "Replay complete"
```

---

## Post-Replay Verification

- [ ] DLQ depth returns to 0
- [ ] Main queue consumers process messages successfully
- [ ] No new DLQ messages within 15 minutes
- [ ] CloudWatch error rate normal
- [ ] Document replay count in incident ticket

---

## Audit Trail

Log every replay operation:
- Who ran the script
- How many messages replayed
- Source DLQ and target queue ARNs
- Link to incident ticket

CloudTrail captures `sqs:SendMessage` and `sqs:DeleteMessage` API calls.
