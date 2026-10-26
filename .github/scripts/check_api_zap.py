"""Sin excepciones del servidor web: cualquier riesgo API bloquea; informativos se revisan."""
import json
from pathlib import Path
import sys
from urllib.parse import urlparse
from staging_api import config

base, _, _ = config()
report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8-sig"))
sites = report.get("site", [])
if not sites or any(urlparse(s.get("@name", "")).netloc != urlparse(base).netloc for s in sites):
    raise SystemExit("Reporte vacío o fuera del origen autorizado.")
blocked = [a["alertRef"] for site in sites for a in site["alerts"] if int(a["riskcode"]) > 0]
print("Alertas bloqueantes API:", ", ".join(blocked) if blocked else "ninguna")
sys.exit(1 if blocked else 0)
