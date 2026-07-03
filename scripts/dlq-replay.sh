#!/usr/bin/env bash
# See docs/operations/runbooks/dlq-replay.md
set -euo pipefail

DLQ_URL="${1:?DLQ queue URL required}"
MAIN_QUEUE_URL="${2:?Main queue URL required}"
MAX_MESSAGES="${3:-10}"

echo "Replaying up to ${MAX_MESSAGES} messages from DLQ to main queue"
echo "Operator: $(aws sts get-caller-identity --query Arn --output text 2>/dev/null || echo 'unknown')"
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
