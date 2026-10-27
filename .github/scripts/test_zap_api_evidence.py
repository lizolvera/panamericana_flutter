import json
import unittest
from unittest.mock import patch

from zap_api_hook import response_metadata, zap_pre_shutdown

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
