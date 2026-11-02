"""Local stand-in for API Gateway: runs the real handler on http://127.0.0.1:5281.

Development only. Run from the repo root, with the venv active:
    python apps/ulid/api/dev_server.py
"""
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qsl, unquote, urlsplit

sys.path.insert(0, str(Path(__file__).parent))
from handler import handler  # noqa: E402

PORT = 5281
PREFIX = "/api/ulid"


def to_event(method: str, raw_path: str) -> dict:
    """Build the same event shape API Gateway's HTTP API sends (payload v2)."""
    parts = urlsplit(raw_path)
    path = unquote(parts.path).rstrip("/")
    query = dict(parse_qsl(parts.query)) or None
    rest = path[len(PREFIX) + 1:]
    if path == PREFIX:
        return {"routeKey": f"{method} {PREFIX}", "queryStringParameters": query, "pathParameters": None}
    if path.startswith(PREFIX + "/") and rest and "/" not in rest:
        return {"routeKey": f"{method} {PREFIX}/{{id}}", "queryStringParameters": query, "pathParameters": {"id": rest}}
    return {"routeKey": f"{method} {path}", "queryStringParameters": query, "pathParameters": None}


class DevHandler(BaseHTTPRequestHandler):
    def _run(self):
        result = handler(to_event(self.command, self.path), None)
        body = result["body"].encode("utf-8")
        self.send_response(result["statusCode"])
        for name, value in result.get("headers", {}).items():
            self.send_header(name, value)
        self.send_header("content-length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    do_GET = _run
    do_POST = _run


if __name__ == "__main__":
    print(f"ULID API on http://127.0.0.1:{PORT}{PREFIX}  (Ctrl+C to stop)")
    try:
        ThreadingHTTPServer(("127.0.0.1", PORT), DevHandler).serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")