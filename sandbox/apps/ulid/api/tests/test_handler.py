import json
from datetime import datetime, timedelta, timezone

import pytest

from handler import MAX_COUNT, handler


def call(route, query=None, path=None):
    event = {"routeKey": route, "queryStringParameters": query, "pathParameters": path}
    response = handler(event, None)
    return response["statusCode"], json.loads(response["body"]), response["headers"]


def test_mints_one_by_default():
    status, body, _ = call("GET /api/ulid")
    assert status == 200 and len(body["ulids"]) == 1


def test_mints_several_in_order():
    status, body, _ = call("GET /api/ulid", {"count": "20"})
    assert status == 200 and len(body["ulids"]) == 20
    assert body["ulids"] == sorted(body["ulids"])  # monotonic, even within one millisecond


@pytest.mark.parametrize("count", ["0", str(MAX_COUNT + 1), "-3"])
def test_count_out_of_range_is_rejected(count):
    status, body, _ = call("GET /api/ulid", {"count": count})
    assert status == 400 and "between" in body["error"]


def test_count_must_be_a_number():
    status, body, _ = call("GET /api/ulid", {"count": "lots"})
    assert status == 400 and "whole number" in body["error"]


def test_checks_a_fresh_ulid_and_decodes_its_time():
    _, minted, _ = call("GET /api/ulid")
    ulid = minted["ulids"][0]
    status, body, _ = call("GET /api/ulid/{id}", path={"id": f" {ulid.lower()} "})
    assert status == 200 and body["valid"] and body["ulid"] == ulid
    when = datetime.fromisoformat(body["timestamp"])
    assert abs(datetime.now(timezone.utc) - when) < timedelta(seconds=5)


def test_invalid_ulid_says_so():
    status, body, _ = call("GET /api/ulid/{id}", path={"id": "not-a-ulid"})
    assert status == 200 and body["valid"] is False


def test_unknown_route_is_404():
    status, _, _ = call("POST /api/ulid")
    assert status == 404


def test_responses_are_never_cached():
    _, _, headers = call("GET /api/ulid")
    assert headers["cache-control"] == "no-store"