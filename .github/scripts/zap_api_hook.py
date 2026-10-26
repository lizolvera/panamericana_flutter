"""Evidencia de rutas protegidas visitadas por ZAP; no guarda datos o tokens."""
import json
import os
from pathlib import Path
from urllib.parse import urlparse


def zap_pre_shutdown(zap):
    base = os.environ["STAGING_API_URL"].rstrip("/")
    required = {"/api/usuarios/perfil", "/api/usuarios/direcciones", "/api/pedidos"}
    found = set()
    total = int(zap.core.number_of_messages(baseurl=base))
    for start in range(0, total, 100):
        for message in zap.core.messages(baseurl=base, start=start, count=100):
            first = message.get("requestHeader", "").splitlines()[0].split()
            status = message.get("responseHeader", "").splitlines()[0].split()
            if len(first) >= 2 and len(status) >= 2:
                path = urlparse(first[1]).path
                if first[0] == "GET" and status[1] == "200" and path in required:
                    found.add(path)
    result = {"protected_paths": sorted(found), "passed": found == required}
    Path("/zap/wrk/reports/zap-api/reached.json").write_text(json.dumps(result))
