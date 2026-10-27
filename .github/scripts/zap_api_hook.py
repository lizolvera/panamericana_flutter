"""Evidencia de rutas protegidas visitadas por ZAP; no guarda datos o tokens."""
import json
import os
import hashlib
import re
from collections import Counter
from pathlib import Path
from urllib.parse import urlparse

PUBLIC_PATHS = {"/", "/api", "/api/health", "/api/productos", "/api/usuarios/perfil",
                "/api/usuarios/direcciones", "/api/pedidos"}


def routing_diagnostic(message, base):
    """Forensic evidence for non-JSON replies without publishing request targets."""
    metadata = response_metadata(message, base)
    if not metadata or metadata[3] in {"application/json", "application/problem+json"}:
        return None
    request_lines = message["requestHeader"].splitlines()
    target = request_lines[0].split()[1]
    parsed = urlparse(target)
    request_headers = {}
    response_headers = {}
    for lines, headers in [(request_lines[1:], request_headers),
                           (message["responseHeader"].splitlines()[1:], response_headers)]:
        for line in lines:
            name, separator, value = line.partition(":")
            if separator:
                headers[name.strip().lower()] = value.strip()
    server = response_headers.get("server", "").lower()
    server = server if server in {"cloudflare", "envoy", "nginx", "render"} else "other"
    expected_host = urlparse(base).netloc.lower()
    body = message.get("responseBody", "").lower()
    flags = []
    for name, matches in [
        ("encoded-control", re.search(r"%(?:00|0a|0d)", parsed.path, re.I)),
        ("encoded-separator", re.search(r"%(?:2f|5c)", parsed.path, re.I)),
        ("invalid-percent-encoding", re.search(r"%(?![0-9a-f]{2})", parsed.path, re.I)),
        ("dot-segments", ".." in parsed.path or "%2e" in parsed.path.lower()),
        ("double-slash", "//" in parsed.path),
        ("backslash", "\\" in parsed.path),
    ]:
        if matches:
            flags.append(name)
    method, path, status, content_type = metadata
    return {"message_id": str(message.get("id", "")) if str(message.get("id", "")).isdigit() else None,
            "method": method, "path": path, "status": status, "content_type": content_type,
            "request_target_sha256": hashlib.sha256(target.encode()).hexdigest(),
            "request_host_matches_staging": request_headers.get("host", "").lower() == expected_host,
            "path_flags": flags, "server": server,
            "backend_headers_present": response_headers.get("x-content-type-options") == "nosniff"
                                       and response_headers.get("cross-origin-resource-policy") == "same-origin",
            "misdirected_request_page": "misdirected request" in body,
            "render_page_marker": "render" in body,
            "cloudflare_page_marker": "cloudflare" in body}


def response_metadata(message, base):
    """Allowlisted metadata only: never copy request/response headers or bodies."""
    request_lines = message.get("requestHeader", "").splitlines()
    response_lines = message.get("responseHeader", "").splitlines()
    if not request_lines or not response_lines:
        return None
    request = request_lines[0].split()
    status = response_lines[0].split()
    if len(request) < 2 or len(status) < 2 or not status[1].isdigit() or len(status[1]) != 3:
        return None
    url = urlparse(request[1])
    target = urlparse(base)
    if url.netloc and (url.scheme, url.netloc) != (target.scheme, target.netloc):
        return None
    method = request[0] if request[0] in {"GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"} else "OTHER"
    # Unknown path segments may contain identifiers or secrets. Never publish them.
    path = url.path if url.path in PUBLIC_PATHS else "/[ruta-no-especificada]"
    content_type = "missing"
    known_types = {"application/json", "application/problem+json", "text/html", "text/plain",
                   "application/xml", "text/xml", "application/octet-stream"}
    for line in response_lines[1:]:
        name, separator, value = line.partition(":")
        if separator and name.lower() == "content-type":
            value = value.strip().split(";", 1)[0].lower()
            content_type = value if value in known_types else "other"
            break
    return method, path, int(status[1]), content_type


def zap_pre_shutdown(zap):
    base = os.environ["STAGING_API_URL"].rstrip("/")
    required = {"/api/usuarios/perfil", "/api/usuarios/direcciones", "/api/pedidos"}
    found = set()
    responses = Counter()
    diagnostics = []
    total = int(zap.core.number_of_messages(baseurl=base))
    for start in range(0, total, 100):
        for message in zap.core.messages(baseurl=base, start=start, count=100):
            metadata = response_metadata(message, base)
            if metadata:
                responses[metadata] += 1
                method, path, status, _ = metadata
                if method == "GET" and status == 200 and path in required:
                    found.add(path)
                diagnostic = routing_diagnostic(message, base)
                if diagnostic:
                    diagnostics.append(diagnostic)
    result = {"protected_paths": sorted(found), "passed": found == required}
    Path("/zap/wrk/reports/zap-api/reached.json").write_text(json.dumps(result))
    details = [{"method": method, "path": path, "status": status,
                "content_type": content_type, "count": count}
               for (method, path, status, content_type), count in sorted(responses.items())]
    Path("/zap/wrk/reports/zap-api/responses.json").write_text(json.dumps(details, indent=2))
    Path("/zap/wrk/reports/zap-api/routing.json").write_text(json.dumps(diagnostics, indent=2))
