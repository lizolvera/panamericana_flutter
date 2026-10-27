"""API gate: risks block, except proven edge rejection of a forged Host."""
import hashlib
import json
from pathlib import Path
import sys
from urllib.parse import urlparse
from zap_api_hook import PUBLIC_PATHS

def proven_edge_rejection(instance, base, routing):
    uri = instance.get("uri", "")
    parsed, target = urlparse(uri), urlparse(base)
    if (parsed.scheme, parsed.netloc) != (target.scheme, target.netloc):
        return False
    if instance.get("method") != "GET" or parsed.path in PUBLIC_PATHS:
        return False
    signature = hashlib.sha256(uri.encode()).hexdigest()
    evidence = [r for r in routing if r.get("request_target_sha256") == signature]
    if not evidence:
        return False
    # Every non-JSON reply for this exact URI must be the same edge rejection.
    if not all(r.get("method") == "GET" and r.get("status") == 421
               and r.get("content_type") == "text/html" and r.get("server") == "cloudflare"
               and r.get("request_host_kind") == "different"
               and r.get("request_host_matches_staging") is False
               and r.get("backend_headers_present") is False
               and r.get("misdirected_request_page") is True
               and r.get("cloudflare_page_marker") is True for r in evidence):
        return False
    # Same-run A/B replay: correcting Host must yield a JSON 404.
    return any(r.get("canonical_host_replay") == {
        "result": "replayed", "status": 404, "content_type": "application/json"
    } for r in evidence)


def check(report, base, routing=()):
    sites = report.get("site", [])
    if not sites or any(urlparse(s.get("@name", "")).netloc != urlparse(base).netloc for s in sites):
        raise ValueError("Reporte vacío o fuera del origen autorizado.")
    blocked, reviewed = [], 0
    for site in sites:
        for alert in site.get("alerts", []):
            if int(alert["riskcode"]) <= 0:
                continue
            instances = alert.get("instances", [])
            if alert["alertRef"] == "100001" and int(alert["riskcode"]) == 1 and instances and all(
                proven_edge_rejection(instance, base, routing) for instance in instances
            ):
                reviewed += len(instances)
            else:
                blocked.append(alert["alertRef"])
    return {"blocked": blocked, "reviewed_edge_rejections": reviewed, "passed": not blocked}


if __name__ == "__main__":
    from staging_api import config
    base, _, _ = config()
    raw = Path(sys.argv[1])
    routing = raw.with_name("routing.json")
    try:
        result = check(json.loads(raw.read_text(encoding="utf-8-sig")), base,
                       json.loads(routing.read_text()) if routing.exists() else [])
    except ValueError as error:
        raise SystemExit(str(error))
    raw.with_name("policy.json").write_text(json.dumps(result, indent=2))
    print("Alertas bloqueantes API:", ", ".join(result["blocked"]) or "ninguna")
    print("Rechazos de Host alterado demostrados por contraste A/B:", result["reviewed_edge_rejections"])
    sys.exit(0 if result["passed"] else 1)
