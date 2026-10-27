"""Configuración temporal del test; jamás subir como artifact ni imprimir."""
import json
import os
from pathlib import Path
from staging_api import config

base, a, _ = config()
path = Path(os.environ["RUNNER_TEMP"]) / "staging-inputs.json"
path.write_text(json.dumps({"API_BASE_URL": base, "STAGING_CLIENT_A_TOKEN": a}), encoding="utf-8")
path.chmod(0o600)
