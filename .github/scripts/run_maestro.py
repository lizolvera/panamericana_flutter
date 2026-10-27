"""Retry only an offline emulator transport, never a failed app assertion."""
from pathlib import Path
import subprocess
import sys
import time

DEVICE = "emulator-5554"
APP = "com.panamericana.panamericana_flutter"


def start_guest(run, output):
    """Use SDK adb for a clean guest launch before Maestro opens its transport."""
    for args, expected in [
        (["shell", "am", "force-stop", APP], None),
        (["shell", "pm", "clear", APP], "Success"),
        # am start -W has a short Android-side first-frame timeout on a cold
        # Flutter debug build. Let Maestro's visible-screen wait verify readiness.
        (["shell", "am", "start", "-n", APP + "/.MainActivity"], "Starting: Intent"),
    ]:
        try:
            result = run(["adb", "-s", DEVICE, *args],
                         capture_output=True, text=True, timeout=60)
        except subprocess.TimeoutExpired:
            output("El arranque limpio de Android agotó el tiempo de espera.")
            return False
        if (result.returncode or "Error:" in result.stdout + result.stderr
                or (expected and expected not in result.stdout)):
            output("No se pudo preparar la app invitada: " + result.stdout + result.stderr)
            return False
    return True


def wait_for_device(run=subprocess.run, sleep=time.sleep):
    stable = 0
    for _ in range(30):
        try:
            result = run(["adb", "-s", "emulator-5554", "shell", "getprop", "sys.boot_completed"],
                         capture_output=True, text=True, timeout=5)
            stable = stable + 1 if result.returncode == 0 and result.stdout.strip() == "1" else 0
            if stable == 3:
                return True
        except subprocess.TimeoutExpired:
            stable = 0
        sleep(2)
    return False


def run_guest(maestro, run=subprocess.run, sleep=time.sleep, output=print):
    command = [maestro, "--device", DEVICE, "test", "--format", "junit", "--output",
               "reports/maestro/results.xml", ".maestro/guest.yaml"]
    for attempt in range(2):
        if not wait_for_device(run, sleep):
            output("El emulador no permanece disponible; la validación falla.")
            return 1
        if not start_guest(run, output):
            return 1
        debug = Path.home() / ".maestro/tests"
        previous = {path: path.stat().st_mtime_ns for path in debug.glob("*/**/commands.json")}
        result = run(command, capture_output=True, text=True)
        text = result.stdout + result.stderr
        output(text)
        if result.returncode == 0:
            return 0
        # Maestro CLI often only prints 'Flow Failed'; its debug commands file
        # contains the actual transport failure. Inspect only this guest run.
        offline = "device offline" in text.lower()
        files = sorted((path for path in debug.glob("*/**/commands.json")
                        if previous.get(path) != path.stat().st_mtime_ns),
                       key=lambda path: path.stat().st_mtime_ns)
        if files:
            offline = offline or "device offline" in files[-1].read_text(encoding="utf-8").lower()
        if not offline or attempt == 1:
            return result.returncode
        output("Transporte Android offline: reconectar y reintentar una vez el flujo invitado.")
        run(["adb", "reconnect", "offline"], capture_output=True, text=True, timeout=15)
        sleep(3)
    return 1


if __name__ == "__main__":
    sys.exit(run_guest(sys.argv[1]))
