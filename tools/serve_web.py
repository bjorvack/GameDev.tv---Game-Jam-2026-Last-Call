#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# ///
"""Serve build/web/ locally with the Cross-Origin-Opener-Policy and
Cross-Origin-Embedder-Policy headers Godot 4 web exports need for
SharedArrayBuffer / WebAssembly threading. Without these headers the
page silently fails to initialise threads and the canvas stays blank.

Defaults to port 8000, serves from build/web/, and prints the URL.
"""
from __future__ import annotations

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class IsolatedHandler(SimpleHTTPRequestHandler):
    def end_headers(self) -> None:
        # Godot 4 web exports rely on cross-origin isolation to be able
        # to use SharedArrayBuffer; without these two headers the page
        # boots but the canvas never paints.
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument(
        "--dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "build" / "web",
        help="Directory to serve (default: build/web/).",
    )
    args = parser.parse_args()

    if not args.dir.is_dir():
        parser.error(f"directory not found: {args.dir} (run tools/build_web.sh first)")
    if not (args.dir / "index.html").is_file():
        parser.error(f"no index.html in {args.dir} — did the export complete?")

    handler = partial(IsolatedHandler, directory=str(args.dir))
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    url = f"http://127.0.0.1:{args.port}/"
    print(f"serving {args.dir} -> {url}")
    print("Ctrl-C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nstopping.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
