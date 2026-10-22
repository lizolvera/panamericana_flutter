"""Gate de CI: bloquea riesgos salvo excepciones puntuales documentadas."""
import json
import sys
from urllib.parse import urlparse


EXCEPTIONS = {
    "90004-2": (1, "COEP require-corp puede bloquear recursos externos de Google; no se habilita aislamiento completo en este servidor de CI."),
    "90004-3": (1, "COOP same-origin-allow-popups conserva el acceso con Google sin FedCM."),
    "10055-6": (2, "Flutter genera estilos inline; se permiten solo estilos, nunca scripts inline ni unsafe-eval."),
}


def check(report):
    sites = report.get("site")
    if not isinstance(sites, list) or not sites:
        raise ValueError("Reporte sin sitios analizados")
    blocked = []
    for site in sites:
        for alert in site["alerts"]:
            risk = int(alert["riskcode"])
            ref = str(alert["alertRef"])
            reason = EXCEPTIONS.get(ref)
            # Las excepciones solo se aplican al servidor temporal escaneado.
            instances = alert.get("instances", [])
            local = bool(instances) and all(
                urlparse(i["uri"]).netloc == "127.0.0.1:8080"
                for i in instances
            )
            if risk == 0:
                print(f"INFO {ref}: {alert['name']}")
            elif reason and risk <= reason[0] and local:
                print(f"EXCEPCIÓN {ref}: {reason[1]}")
            else:
                blocked.append(ref)
                print(f"BLOQUEO {ref}: {alert['name']}")
    return blocked


if __name__ == "__main__":
    # Archivo ausente, JSON inválido o formato inesperado también falla el job.
    with open(sys.argv[1], encoding="utf-8-sig") as source:
        blocked = check(json.load(source))
    sys.exit(1 if blocked else 0)
