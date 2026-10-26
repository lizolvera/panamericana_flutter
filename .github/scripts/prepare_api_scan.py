"""OpenAPI reducido: solo GET de la API propia; sin login, pagos ni mutaciones."""
import json
from pathlib import Path
from staging_api import config

base, _, _ = config()
paths = ["/api/productos", "/api/usuarios/perfil", "/api/usuarios/direcciones", "/api/pedidos"]
schema = {"openapi": "3.0.3", "info": {"title": "Panamericana staging read-only", "version": "1.0"},
          "servers": [{"url": base}], "paths": {}}
for path in paths:
    schema["paths"][path] = {"get": {"responses": {"200": {"description": "JSON"}}}}
Path("reports/zap-api").mkdir(parents=True, exist_ok=True)
Path("reports/zap-api/openapi.json").write_text(json.dumps(schema, indent=2), encoding="utf-8")
