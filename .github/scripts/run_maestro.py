"""Retry only an offline emulator transport, never a failed app assertion."""
from pathlib import Path
import subprocess
import sys
import time


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
    command = [maestro, "test", "--format", "junit", "--output",
               "reports/maestro/results.xml", ".maestro/guest.yaml"]
    for attempt in range(2):
        if not wait_for_device(run, sleep):
            output("El emulador no permanece disponible; la validación falla.")
            return 1
        result = run(command, capture_output=True, text=True)
        text = result.stdout + result.stderr
        output(text)
        if result.returncode == 0:
            return 0
        # Maestro CLI often only prints 'Flow Failed'; its debug commands file
        # contains the actual transport failure. Inspect only this guest run.
        offline = "device offline" in text.lower()
        debug = Path.home() / ".maestro/tests"
        files = sorted(debug.glob("*/**/commands.json"), key=lambda path: path.stat().st_mtime)
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
