"""Manifiesto de trazabilidad sin secretos ni variables de entorno completas."""
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import platform
import subprocess


def version(command):
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=30)
        return result.stdout.strip()[:2000] if result.returncode == 0 else "unavailable"
    except (OSError, subprocess.TimeoutExpired):
        return "unavailable"


manifest = {
    "commit": os.environ.get("GITHUB_SHA"),
    "run": os.environ.get("GITHUB_RUN_ID"),
    "attempt": os.environ.get("GITHUB_RUN_ATTEMPT"),
    "job": os.environ.get("GITHUB_JOB"),
    "ref": os.environ.get("GITHUB_REF"),
    "utc": datetime.now(timezone.utc).isoformat(),
    "runner": platform.platform(),
    "python": platform.python_version(),
    "flutter": version(["flutter", "--version", "--machine"]),
    "zap_image": version(["docker", "image", "inspect", "ghcr.io/zaproxy/zaproxy:stable", "--format", "{{json .RepoDigests}}"]),
    "k6_image": version(["docker", "image", "inspect", "grafana/k6:1.3.0", "--format", "{{json .RepoDigests}}"]),
    "android_api": version(["adb", "shell", "getprop", "ro.build.version.sdk"]),
}
Path("reports").mkdir(exist_ok=True)
Path("reports/manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
