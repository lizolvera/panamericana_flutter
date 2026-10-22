import json
from functools import partial
from http.server import ThreadingHTTPServer
from pathlib import Path
from tempfile import TemporaryDirectory
from threading import Thread
import unittest
from urllib.error import HTTPError
from urllib.request import urlopen

from check_zap import check
from serve_web import WebHandler


class SecurityTests(unittest.TestCase):
    def test_headers_on_success_and_error(self):
        with TemporaryDirectory() as directory:
            Path(directory, "index.html").write_text("<html></html>")
            server = ThreadingHTTPServer(
                ("127.0.0.1", 0), partial(WebHandler, directory=directory)
            )
            thread = Thread(target=server.serve_forever, daemon=True)
            thread.start()
            try:
                base = f"http://127.0.0.1:{server.server_port}"
                for path in ["/", "/missing"]:
                    try:
                        response = urlopen(base + path)
                    except HTTPError as error:
                        response = error
                    with response:
                        self.assertEqual(response.headers["X-Frame-Options"], "DENY")
                        self.assertEqual(response.headers["X-Content-Type-Options"], "nosniff")
                        self.assertEqual(response.headers["Cache-Control"], "no-store")
                        self.assertEqual(response.headers["Server"], "Web")
                        csp = response.headers["Content-Security-Policy"]
                        self.assertIn("frame-ancestors 'none'", csp)
                        scripts = next(d for d in csp.split(";") if d.strip().startswith("script-src"))
                        self.assertNotIn("'unsafe-inline'", scripts)
                        self.assertNotIn("'unsafe-eval'", scripts)
            finally:
                server.shutdown()
                server.server_close()
                thread.join()

    def test_gate_blocks_unexpected_risks(self):
        def report(ref, risk, host="127.0.0.1:8080"):
            return {"site": [{"alerts": [{
                "alertRef": ref, "riskcode": str(risk), "name": "Example",
                "instances": [{"uri": f"http://{host}/"}],
            }]}]}
        self.assertEqual(check(report("10109", 0)), [])
        self.assertEqual(check(report("90004-3", 1)), [])
        self.assertTrue(check(report("90004-3", 3)))
        self.assertTrue(check(report("90004-3", 1, "production.example")))
        self.assertTrue(check(report("10038-1", 2)))
        self.assertTrue(check(report("10055-5", 2)))
        self.assertTrue(check(report("unknown", 1)))
        with self.assertRaises(ValueError):
            check({"site": []})


if __name__ == "__main__":
    unittest.main()
