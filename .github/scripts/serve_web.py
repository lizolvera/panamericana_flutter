"""Servidor de CI; no sustituye la configuración del hosting de producción."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class WebHandler(SimpleHTTPRequestHandler):
    # No publicar versiones del intérprete ni del servidor.
    def version_string(self):
        return "Web"

    def end_headers(self):
        headers = {
            "Content-Security-Policy": "; ".join([
                "default-src 'self'",
                "base-uri 'self'",
                "object-src 'none'",
                "frame-ancestors 'none'",
                "form-action 'self'",
                "script-src 'self' 'wasm-unsafe-eval' https://www.gstatic.com/flutter-canvaskit/ https://accounts.google.com/gsi/client",
                # Flutter genera estilos en ejecución; no se permiten scripts inline.
                "style-src 'self' 'unsafe-inline' https://accounts.google.com/gsi/style https://fonts.googleapis.com",
                "connect-src 'self' https://prybinaback.onrender.com https://www.gstatic.com/flutter-canvaskit/ https://fonts.gstatic.com https://accounts.google.com/gsi/",
                "font-src 'self' https://fonts.gstatic.com",
                "img-src 'self' data: blob: https://res.cloudinary.com https://lh3.googleusercontent.com",
                "frame-src https://accounts.google.com/gsi/",
                "worker-src 'self' blob:",
                "manifest-src 'self'",
            ]),
            "X-Frame-Options": "DENY",
            "X-Content-Type-Options": "nosniff",
            "Permissions-Policy": "camera=(), microphone=(), geolocation=(self), payment=(self)",
            "Referrer-Policy": "strict-origin-when-cross-origin",
            "Cross-Origin-Resource-Policy": "same-origin",
            # Google OAuth sin FedCM requiere comunicación con su popup.
            "Cross-Origin-Opener-Policy": "same-origin-allow-popups",
            "Cache-Control": "no-store",
        }
        for name, value in headers.items():
            self.send_header(name, value)
        super().end_headers()

    def list_directory(self, path):
        self.send_error(403, "Directory listing disabled")
        return None


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", default="build/web")
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()
    handler = partial(WebHandler, directory=args.directory)
    ThreadingHTTPServer(("127.0.0.1", args.port), handler).serve_forever()
