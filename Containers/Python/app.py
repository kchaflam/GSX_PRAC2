import os
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

DATA_FILE = "/data/log.txt"

# Ensure volume directory exists
os.makedirs("/data", exist_ok=True)

# Write persistent log on container start
with open(DATA_FILE, "a") as f:
    f.write(f"Container started at {datetime.now()}.\n")

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/logs":
            # Read persisted volume data
            try:
                with open(DATA_FILE, "r") as f:
                    content = f.read()
            except FileNotFoundError:
                content = "No logs found."

            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(content.encode())

        else:
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Backend is running!")

PORT = int(os.getenv("PORT", 8080))

server = HTTPServer(("0.0.0.0", PORT), Handler)

print(f"Server running on port {PORT}")

server.serve_forever()