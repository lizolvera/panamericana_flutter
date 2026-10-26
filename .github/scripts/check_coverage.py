"""Cobertura de todo lib: el alcance y el mínimo se versionan, no se ajustan al resultado."""
import json
from pathlib import Path
import sys


def coverage(path):
    records = {}
    current = None
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        if line.startswith("SF:"):
            current = line[3:].replace("\\", "/")
            records.setdefault(current, {})
        elif line.startswith("DA:") and current:
            number, count, *_ = line[3:].split(",")
            records[current][int(number)] = max(int(count), records[current].get(int(number), 0))
    return records


if __name__ == "__main__":
    records = coverage(sys.argv[1])
    if not records:
        raise SystemExit("No hay datos de cobertura; no se considera aprobado.")
    total = sum(len(lines) for lines in records.values())
    covered = sum(sum(n > 0 for n in lines.values()) for lines in records.values())
    percent = 100 * covered / total if total else 0
    result = {"scope": "all instrumented lib files", "lines": total, "covered": covered,
              "percent": round(percent, 2), "minimum": 80, "passed": total > 0 and percent >= 80}
    Path("coverage/summary.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(f"Cobertura: {percent:.2f}% ({covered}/{total}); mínimo: 80%")
    sys.exit(0 if result["passed"] else 1)
