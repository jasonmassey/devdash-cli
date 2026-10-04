#!/usr/bin/env python3
"""Receive only the one-time OAuth code from the local browser callback."""

import http.server
import re
import signal
import sys
import threading
import urllib.parse


port, nonce, code_file, ready_file = sys.argv[1:]


class Callback(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlsplit(self.path)
        values = urllib.parse.parse_qs(parsed.query, keep_blank_values=True)
        code = values.get("code", [])
        received_nonce = values.get("nonce", [])
        valid = (
            parsed.path == "/callback"
            and len(code) == 1
            and len(received_nonce) == 1
            and received_nonce[0] == nonce
            and re.fullmatch(r"[A-Za-z0-9_-]{32,256}", code[0]) is not None
            and set(values) == {"code", "nonce"}
        )
        self.send_response(200 if valid else 400)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Referrer-Policy", "no-referrer")
        self.end_headers()
        if valid:
            with open(code_file, "w", encoding="ascii") as output:
                output.write(code[0])
            self.wfile.write(b"<html><body>Return to your terminal to complete sign-in.</body></html>")
            threading.Thread(target=self.server.shutdown, daemon=True).start()
        else:
            self.wfile.write(b"Invalid callback")

    def log_message(self, *args):
        # The request path contains a short-lived credential; never log it.
        pass


signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
server = http.server.HTTPServer(("127.0.0.1", int(port)), Callback)
with open(ready_file, "w", encoding="ascii") as output:
    output.write("ready")
timer = threading.Timer(120, server.shutdown)
timer.daemon = True
timer.start()
server.serve_forever()
