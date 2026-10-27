"""Publicar solo metadatos del reporte: nunca cuerpos, JWT o cabeceras."""
import html
import json
from pathlib import Path

raw = Path("reports/zap-api/raw.json")
out = Path("reports/zap-api/public")
out.mkdir(parents=True, exist_ok=True)
if raw.exists():
    report = json.loads(raw.read_text(encoding="utf-8-sig"))
    alerts = [{"id": a["alertRef"], "name": a["name"], "risk": a["riskdesc"],
               "instances": len(a.get("instances", []))}
              for site in report.get("site", []) for a in site.get("alerts", [])]
    (out / "alerts.json").write_text(json.dumps(alerts, indent=2), encoding="utf-8")
    rows = "".join("<tr>" + "".join("<td>" + html.escape(str(a[k])) + "</td>"
                                    for k in ["id", "name", "risk", "instances"]) + "</tr>" for a in alerts)
    (out / "report.html").write_text('<!doctype html><meta charset="utf-8"><title>ZAP API</title>'
        '<h1>ZAP API staging</h1><table><tr><th>ID</th><th>Alerta</th><th>Riesgo</th><th>Casos</th></tr>' + rows + '</table>', encoding="utf-8")
responses = Path("reports/zap-api/responses.json")
if responses.exists():
    # This file is generated from allowlisted metadata by zap_api_hook.py.
    details = json.loads(responses.read_text(encoding="utf-8"))
    (out / "responses.json").write_text(json.dumps(details, indent=2), encoding="utf-8")
    if (out / "report.html").exists():
        rows = "".join("<tr>" + "".join("<td>" + html.escape(str(r[k])) + "</td>"
                        for k in ["method", "path", "status", "content_type", "count"]) + "</tr>" for r in details)
        with (out / "report.html").open("a", encoding="utf-8") as report:
            report.write('<h2>Respuestas observadas (sin datos personales)</h2><table>'
                         '<tr><th>Método</th><th>Ruta</th><th>HTTP</th><th>Content-Type</th><th>Casos</th></tr>' + rows + '</table>')
reached = Path("reports/zap-api/reached.json")
if reached.exists():
    (out / "reached.json").write_text(reached.read_text(), encoding="utf-8")
