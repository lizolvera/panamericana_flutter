import copy
import hashlib
import unittest
from check_api_zap import check

BASE = "https://staging.example.test"
URI = BASE + "/probe-only"


class ApiZapGateTests(unittest.TestCase):
    def fixture(self):
        report = {"site": [{"@name": BASE, "alerts": [{"alertRef": "100001", "riskcode": "1",
                  "instances": [{"method": "GET", "uri": URI}]}]}]}
        routing = [{"request_target_sha256": hashlib.sha256(URI.encode()).hexdigest(),
                    "method": "GET", "status": 421, "content_type": "text/html", "server": "cloudflare",
                    "request_host_kind": "different", "request_host_matches_staging": False,
                    "backend_headers_present": False, "misdirected_request_page": True,
                    "cloudflare_page_marker": True, "canonical_host_replay": {
                        "result": "replayed", "status": 404, "content_type": "application/json"}}]
        return report, routing

    def test_proven_forged_host_rejection_is_reviewed_not_hidden(self):
        report, routing = self.fixture()
        result = check(report, BASE, routing)
        self.assertTrue(result["passed"])
        self.assertEqual(result["reviewed_edge_rejections"], 1)
        self.assertEqual(report["site"][0]["alerts"][0]["alertRef"], "100001")

    def test_missing_or_inconclusive_evidence_blocks(self):
        report, routing = self.fixture()
        self.assertFalse(check(report, BASE)["passed"])
        for field, value in [("request_host_kind", "expected"), ("backend_headers_present", True),
                             ("status", 200), ("misdirected_request_page", False),
                             ("canonical_host_replay", {"result": "inconclusive"})]:
            altered = copy.deepcopy(routing)
            altered[0][field] = value
            self.assertFalse(check(report, BASE, altered)["passed"], field)

    def test_valid_api_route_or_other_risk_always_blocks(self):
        report, routing = self.fixture()
        report["site"][0]["alerts"][0]["instances"][0]["uri"] = BASE + "/api/productos"
        self.assertFalse(check(report, BASE, routing)["passed"])
        report, routing = self.fixture()
        report["site"][0]["alerts"][0]["alertRef"] = "10098"
        self.assertFalse(check(report, BASE, routing)["passed"])
        report, routing = self.fixture()
        report["site"][0]["alerts"][0]["riskcode"] = "3"
        self.assertFalse(check(report, BASE, routing)["passed"])

    def test_one_unexplained_instance_or_reply_keeps_gate_closed(self):
        report, routing = self.fixture()
        report["site"][0]["alerts"][0]["instances"].append({"method": "GET", "uri": BASE + "/other"})
        self.assertFalse(check(report, BASE, routing)["passed"])
        report, routing = self.fixture()
        altered = copy.deepcopy(routing[0]); altered["status"] = 500
        routing.append(altered)
        self.assertFalse(check(report, BASE, routing)["passed"])

    def test_empty_and_foreign_reports_are_rejected(self):
        for report in [{"site": []}, {"site": [{"@name": "https://production.example"}]}]:
            with self.assertRaises(ValueError):
                check(report, BASE)
