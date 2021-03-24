#!/bin/env python
from http.server import HTTPServer, BaseHTTPRequestHandler
import sys

ip = sys.argv[1]
port = int(sys.argv[2])
message = sys.argv[3]

class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(bytes(message + "\n", "utf-8"))
    def log_message(self, format, *args):
        return

httpd = HTTPServer((ip, port), MyHandler)
httpd.serve_forever()
