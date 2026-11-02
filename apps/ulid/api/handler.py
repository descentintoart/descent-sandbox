import json

from ulidlib import is_valid, new_ulid, timestamp_of

MAX_COUNT = 100


def respond(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json", "cache-control": "no-store"},
        "body": json.dumps(body),
    }


def handler(event, context):
    """API Gateway HTTP API (payload v2). Two routes, everything else is a 404."""
    route = event.get("routeKey", "")

    if route == "GET /api/ulid":
        raw = (event.get("queryStringParameters") or {}).get("count", "1")
        try:
            count = int(raw)
        except ValueError:
            return respond(400, {"error": f"count must be a whole number, got {raw!r}"})
        if not 1 <= count <= MAX_COUNT:
            return respond(400, {"error": f"count must be between 1 and {MAX_COUNT}"})
        return respond(200, {"ulids": [new_ulid() for _ in range(count)]})

    if route == "GET /api/ulid/{id}":
        value = (event.get("pathParameters") or {}).get("id", "").strip().upper()
        if not is_valid(value):
            return respond(200, {"ulid": value, "valid": False})
        when = timestamp_of(value)
        return respond(200, {
            "ulid": value,
            "valid": True,
            "timestamp": when.isoformat(),
            "unix_ms": round(when.timestamp() * 1000),
        })

    return respond(404, {"error": f"no such route: {route}"})