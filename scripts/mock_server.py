#!/usr/bin/env python3
"""本地模拟内容源：把 assets/demo/feed.json 暴露成 /feed 与 /item/<id>。

用法：
    python3 scripts/mock_server.py                    # 监听 0.0.0.0:8787
    python3 scripts/mock_server.py --port 9000        # 换端口
    python3 scripts/mock_server.py --host 127.0.0.1   # 只允许本机

真机调试时用电脑局域网 IP，例如 http://192.168.1.10:8787。
只依赖标准库，不需要装任何东西。
"""

from __future__ import annotations

import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
FEED_FILE = ROOT / "assets" / "demo" / "feed.json"


def load_feed() -> dict[str, Any]:
    with FEED_FILE.open("r", encoding="utf-8") as handle:
        return json.load(handle)


class Handler(BaseHTTPRequestHandler):
    server_version = "OneReaderMock/0.1"

    def _send(self, status: int, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self) -> None:  # noqa: N802（标准库要求的命名）
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        path = self.path.split("?", 1)[0].rstrip("/") or "/"
        feed = load_feed()

        if path in ("/", "/feed"):
            self._send(200, feed)
            return

        if path.startswith("/item/"):
            item_id = path[len("/item/"):]
            detail = feed.get("details", {}).get(item_id)
            if detail is None:
                self._send(404, {"error": "not_found", "id": item_id})
                return
            self._send(200, detail)
            return

        self._send(404, {"error": "not_found", "path": path})

    def log_message(self, fmt: str, *args: Any) -> None:
        print(f"[mock] {self.address_string()} {fmt % args}")


def main() -> None:
    parser = argparse.ArgumentParser(description="One Reader 本地模拟内容源")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8787)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"mock source: http://{args.host}:{args.port}/feed")
    if args.host == "0.0.0.0":
        print("Android 模拟器请填 http://10.0.2.2:%d" % args.port)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nbye")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
