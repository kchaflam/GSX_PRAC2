import os
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(b"The app container is working fine!")

# Leer puerto desde variable de entorno
PORT = int(os.getenv("PORT"))

server = HTTPServer(("0.0.0.0", PORT), Handler)

print(f"Server running on port {PORT}")

server.serve_forever()