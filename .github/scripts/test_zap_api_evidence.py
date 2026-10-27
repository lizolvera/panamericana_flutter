import json
import unittest
from unittest.mock import patch

from zap_api_hook import response_metadata, routing_diagnostic, replay_canonical_host, zap_pre_shutdown

BASE = "https://staging.example.test"


class ZapApiEvidenceTests(unittest.TestCase):
    def message(self, path="/api/usuarios/perfil?token=SECRET", content_type="text/html; charset=utf-8"):
        return {"requestHeader": f"GET {BASE}{path} HTTP/1.1\r\nAuthorization: SECRET\r\nCookie: SECRET",
                "responseHeader": f"HTTP/1.1 404 Not Found\r\nContent-Type: {content_type}\r\nSet-Cookie: SECRET",
                "responseBody": "PRIVATE-BODY", "requestBody": "PRIVATE-BODY"}

    def test_metadata_reports_content_type_without_credentials_or_query(self):
        result = response_metadata(self.message(), BASE)
        self.assertEqual(result, ("GET", "/api/usuarios/perfil", 404, "text/html"))
        self.assertNotIn("SECRET", json.dumps(result))

    def test_unknown_path_and_type_are_redacted(self):
        result = response_metadata(self.message("/api/usuarios/private-person@example.test", "application/SECRET"), BASE)
        self.assertEqual(result, ("GET", "/[ruta-no-especificada]", 404, "other"))

    def test_root_and_missing_type_are_diagnosable(self):
        self.assertEqual(response_metadata(self.message("/"), BASE)[1], "/")
        message = self.message()
        message["responseHeader"] = "HTTP/1.1 204 No Content"
        self.assertEqual(response_metadata(message, BASE)[3], "missing")

    def test_ignores_external_or_malformed_messages(self):
        message = self.message()
        message["requestHeader"] = "GET https://external.example/api/productos HTTP/1.1"
        self.assertIsNone(response_metadata(message, BASE))
        self.assertIsNone(response_metadata({}, BASE))

    def test_routing_evidence_identifies_edge_reply_without_disclosing_data(self):
        message = self.message("/api/person@example.test/%00?token=SECRET")
        message["requestHeader"] += "\r\nHost: unexpected-host.example"
        message["responseHeader"] = "HTTP/1.1 421 Misdirected Request\r\nServer: cloudflare\r\nContent-Type: text/html"
        message["responseBody"] = "<title>Misdirected Request</title> PRIVATE-BODY SECRET"
        result = routing_diagnostic(message, BASE)
        self.assertFalse(result["request_host_matches_staging"])
        self.assertFalse(result["backend_headers_present"])
        self.assertTrue(result["misdirected_request_page"])
        self.assertEqual(result["server"], "cloudflare")
        self.assertEqual(result["path_flags"], ["encoded-control"])
        serialized = json.dumps(result)
        for secret in ["SECRET", "PRIVATE-BODY", "person@example.test", "unexpected-host.example"]:
            self.assertNotIn(secret, serialized)

    def test_routing_evidence_preserves_backend_failures_for_investigation(self):
        message = self.message("/", "text/html")
        message["requestHeader"] += "\r\nHost: staging.example.test"
        message["responseHeader"] += "\r\nX-Content-Type-Options: nosniff\r\nCross-Origin-Resource-Policy: same-origin"
        result = routing_diagnostic(message, BASE)
        self.assertTrue(result["request_host_matches_staging"])
        self.assertTrue(result["backend_headers_present"])
        self.assertEqual(result["status"], 404)
        self.assertIsNone(routing_diagnostic(self.message(content_type="application/json"), BASE))

    def test_replay_is_get_only_same_origin_and_strips_credentials(self):
        class Core:
            def send_request(inner, request, **_):
                self.assertNotIn("SECRET", request)
                self.assertNotIn("Cookie", request)
                return [{"requestHeader": request, "responseHeader": "HTTP/1.1 401 Unauthorized\r\nContent-Type: application/json"}]
        class Zap:
            core = Core()
        message = self.message("/api/usuarios/perfil")
        self.assertEqual(replay_canonical_host(Zap(), message, BASE)["status"], 401)
        message["requestHeader"] = message["requestHeader"].replace("GET ", "POST ", 1)
        self.assertEqual(replay_canonical_host(Zap(), message, BASE)["result"], "not-replayed")

    def test_default_tls_port_does_not_falsely_imply_host_injection(self):
        message = self.message("/")
        message["requestHeader"] += "\r\nHost: staging.example.test:443"
        self.assertTrue(routing_diagnostic(message, BASE)["request_host_matches_staging"])

    def test_hook_counts_only_successfully_reached_protected_routes(self):
        class Core:
            def number_of_messages(self, **_): return "4"
            def messages(inner, **_):
                messages = [self.message(path, "application/json") for path in
                            ["/api/usuarios/perfil", "/api/usuarios/direcciones", "/api/pedidos"]]
                for message in messages:
                    message["responseHeader"] = message["responseHeader"].replace("404 Not Found", "200 OK")
                return messages + [self.message("/")]
        class Zap:
            core = Core()
        with patch.dict("os.environ", {"STAGING_API_URL": BASE}), patch("zap_api_hook.Path.write_text") as write:
            zap_pre_shutdown(Zap())
        reached = json.loads(write.call_args_list[0].args[0])
        self.assertTrue(reached["passed"])
        details = write.call_args_list[1].args[0]
        self.assertNotIn("SECRET", details)
        self.assertNotIn("PRIVATE-BODY", details)
        self.assertIn('"text/html"', details)


if __name__ == "__main__":
    unittest.main()
