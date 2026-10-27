"""Contrato de solo lectura e aislamiento entre dos clientes sintéticos."""
import json
import os
from pathlib import Path
import sys
from urllib.error import HTTPError
from urllib.parse import urlparse
from urllib.request import Request, build_opener, HTTPRedirectHandler


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def config():
    base = os.environ.get("STAGING_API_URL", "").rstrip("/")
    parsed = urlparse(base)
    if (parsed.scheme != "https" or not parsed.hostname or parsed.username
            or parsed.password or parsed.query or parsed.fragment or parsed.path
            or parsed.hostname.lower().rstrip(".") == "prybinaback.onrender.com"):
        raise ValueError("Configura STAGING_API_URL con el origen HTTPS de staging, separado de producción.")
    a = os.environ.get("STAGING_CLIENT_A_TOKEN", "")
    b = os.environ.get("STAGING_CLIENT_B_TOKEN", "")
    if not a or not b or a == b:
        raise ValueError("Se requieren tokens vigentes de dos clientes sintéticos diferentes.")
    return base, a, b


def get(base, path, token=None):
    headers = {"Accept": "application/json"}
    if token:
        headers["Authorization"] = token  # API del proyecto: JWT sin Bearer.
    try:
        response = build_opener(NoRedirect).open(Request(base + path, headers=headers), timeout=30)
    except HTTPError as error:
        response = error
    with response:
        status = response.status
        raw = response.read()
        try:
            data = json.loads(raw)
        except (ValueError, UnicodeError):
            data = None
    return status, data


def run():
    base, a, b = config()
    checks = []
    def require(name, ok):
        checks.append({"case": name, "passed": bool(ok)})
        if not ok:
            raise AssertionError(name)

    require("catálogo público JSON", (lambda r: r[0] == 200 and isinstance(r[1], list))(get(base, "/api/productos")))
    for path in ["/api/usuarios/perfil", "/api/usuarios/direcciones", "/api/pedidos"]:
        require("sin token: " + path, get(base, path)[0] == 401)
        require("token inválido: " + path, get(base, path, "invalid-ci-token")[0] == 401)
    ids = []
    orders = []
    for label, token in [("A", a), ("B", b)]:
        status, profile = get(base, "/api/usuarios/perfil", token)
        require("perfil cliente " + label, status == 200 and isinstance(profile, dict)
                and profile.get("rol") == "usuario" and bool(profile.get("_id")))
        ids.append(str(profile["_id"]))
        require("direcciones " + label, (lambda r: r[0] == 200 and isinstance(r[1], list))(get(base, "/api/usuarios/direcciones", token)))
        status, items = get(base, "/api/pedidos", token)
        require("pedidos sintéticos " + label, status == 200 and isinstance(items, list) and len(items) > 0)
        for order in items:
            owner = order.get("usuario")
            owner_id = owner.get("_id") if isinstance(owner, dict) else owner
            require("lista aislada " + label, str(owner_id) == ids[-1])
        orders.append(items)
        require("cliente no accede a administración " + label,
                get(base, "/api/usuarios/admin/usuarios", token)[0] == 403)
    require("clientes diferentes", ids[0] != ids[1])
    for label, token, other in [("A", a, orders[1]), ("B", b, orders[0])]:
        order_id = str(other[0]["_id"])
        require("ID de pedido válido", len(order_id) == 24 and all(c in "0123456789abcdef" for c in order_id.lower()))
        require("detalle ajeno denegado " + label,
                get(base, "/api/pedidos/" + order_id, token)[0] in (403, 404))
    return checks


if __name__ == "__main__":
    Path("reports/api").mkdir(parents=True, exist_ok=True)
    try:
        checks = run()
    except Exception as error:
        # No registrar cabeceras, cuerpos, tokens, datos personales ni mensajes de red.
        status = "failed" if isinstance(error, AssertionError) else "inconclusive"
        result = {"passed": False, "status": status, "reason": type(error).__name__}
        if isinstance(error, (AssertionError, ValueError)):
            result["case"] = str(error)
        Path("reports/api/result.json").write_text(json.dumps(result))
        print("Contrato de staging fallido o inconcluso. Revisa URL, tokens, datos y disponibilidad.")
        sys.exit(1)
    Path("reports/api/result.json").write_text(json.dumps({"passed": True, "checks": checks}, indent=2))
    print(f"API staging: {len(checks)} comprobaciones aprobadas.")
