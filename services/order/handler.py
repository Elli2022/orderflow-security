"""
OrderFlow Order Lambda — minimal reference implementation.
Security focus: idempotency, PII-safe logging, least-privilege IAM (see Terraform).
"""
import json
import logging
import os
import uuid
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

dynamodb = boto3.resource("dynamodb")
events = boto3.client("events")

ORDERS_TABLE = os.environ["ORDERS_TABLE"]
IDEMPOTENCY_TABLE = os.environ["IDEMPOTENCY_TABLE"]
EVENT_BUS_NAME = os.environ["EVENT_BUS_NAME"]

orders_table = dynamodb.Table(ORDERS_TABLE)
idempotency_table = dynamodb.Table(IDEMPOTENCY_TABLE)

SENSITIVE_FIELDS = {"customerEmail", "customerName", "email", "name"}


def _redact(obj: dict) -> dict:
    """Remove PII from objects before logging."""
    return {k: ("***" if k in SENSITIVE_FIELDS else v) for k, v in obj.items()}


def _response(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def _get_claims(event: dict) -> dict:
    return event.get("requestContext", {}).get("authorizer", {}).get("jwt", {}).get("claims", {})


def _check_idempotency(key: str) -> dict | None:
    try:
        result = idempotency_table.get_item(Key={"idempotencyKey": key})
        return result.get("Item")
    except ClientError:
        logger.exception("Idempotency check failed")
        raise


def _store_idempotency(key: str, order_id: str) -> bool:
    ttl = int(datetime.now(timezone.utc).timestamp()) + 86400 * 30
    try:
        idempotency_table.put_item(
            Item={
                "idempotencyKey": key,
                "orderId": order_id,
                "expiresAt": ttl,
            },
            ConditionExpression="attribute_not_exists(idempotencyKey)",
        )
        return True
    except ClientError as e:
        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            return False
        raise


def _publish_order_created(order_id: str, customer_id: str, correlation_id: str) -> None:
    """Publish event without PII — SEC-010."""
    events.put_events(
        Entries=[
            {
                "Source": "orderflow.order",
                "DetailType": "OrderCreated",
                "EventBusName": EVENT_BUS_NAME,
                "Detail": json.dumps(
                    {
                        "eventId": f"evt_{uuid.uuid4().hex[:12]}",
                        "orderId": order_id,
                        "customerId": customer_id,
                        "status": "PENDING",
                        "correlationId": correlation_id,
                        "timestamp": datetime.now(timezone.utc).isoformat(),
                    }
                ),
            }
        ]
    )


def _create_order(order_id: str, body: dict, customer_id: str, correlation_id: str) -> dict:
    now = datetime.now(timezone.utc).isoformat()

    item = {
        "orderId": order_id,
        "customerId": customer_id,
        "items": body.get("items", []),
        "status": "PENDING",
        "correlationId": correlation_id,
        "createdAt": now,
        "version": 1,
    }

    if "customerEmail" in body:
        item["customerEmail"] = body["customerEmail"]
    if "customerName" in body:
        item["customerName"] = body["customerName"]

    orders_table.put_item(
        Item=item,
        ConditionExpression="attribute_not_exists(orderId)",
    )
    _publish_order_created(order_id, customer_id, correlation_id)
    return item


def _get_order(order_id: str, customer_id: str) -> dict | None:
    result = orders_table.get_item(Key={"orderId": order_id})
    item = result.get("Item")
    if not item:
        return None
    if item.get("customerId") != customer_id:
        return None
    return item


def lambda_handler(event, context):
    correlation_id = event.get("requestContext", {}).get("requestId", str(uuid.uuid4()))
    claims = _get_claims(event)
    customer_id = claims.get("sub", "unknown")

    route_key = event.get("routeKey", "")
    logger.info(
        json.dumps(
            {
                "correlationId": correlation_id,
                "routeKey": route_key,
                "customerId": customer_id,
                "action": "request_received",
            }
        )
    )

    try:
        if route_key == "POST /orders":
            headers = event.get("headers") or {}
            idempotency_key = headers.get("idempotency-key") or headers.get("Idempotency-Key")

            if not idempotency_key:
                return _response(400, {"error": "Idempotency-Key header required"})

            existing = _check_idempotency(idempotency_key)
            if existing:
                order = _get_order(existing["orderId"], customer_id)
                if order:
                    return _response(200, {"orderId": order["orderId"], "status": order["status"], "idempotent": True})

            body = json.loads(event.get("body") or "{}")
            logger.info(json.dumps({"correlationId": correlation_id, "payload": _redact(body)}))

            if not body.get("items"):
                return _response(400, {"error": "items required"})

            order_id = f"ord_{uuid.uuid4().hex[:12]}"
            if not _store_idempotency(idempotency_key, order_id):
                existing = _check_idempotency(idempotency_key)
                if existing:
                    order = _get_order(existing["orderId"], customer_id)
                    if order:
                        return _response(200, {"orderId": order["orderId"], "status": order["status"], "idempotent": True})

            order = _create_order(order_id, body, customer_id, correlation_id)
            return _response(201, {"orderId": order["orderId"], "status": order["status"]})

        if route_key == "GET /orders/{orderId}":
            order_id = event.get("pathParameters", {}).get("orderId")
            if not order_id:
                return _response(400, {"error": "orderId required"})

            order = _get_order(order_id, customer_id)
            if not order:
                return _response(404, {"error": "Order not found"})

            return _response(
                200,
                {
                    "orderId": order["orderId"],
                    "status": order["status"],
                    "items": order.get("items", []),
                    "createdAt": order.get("createdAt"),
                },
            )

        return _response(404, {"error": "Not found"})

    except ClientError:
        logger.exception(json.dumps({"correlationId": correlation_id, "error": "aws_client_error"}))
        return _response(500, {"error": "Internal server error"})
    except Exception:
        logger.exception(json.dumps({"correlationId": correlation_id, "error": "unexpected_error"}))
        return _response(500, {"error": "Internal server error"})
