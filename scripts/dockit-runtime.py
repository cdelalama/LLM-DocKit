#!/usr/bin/env python3
"""Read-only validation of declared runtime retirement receipts; no host access."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re

KEY = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,127}")

def require(ok, message):
    if not ok:
        raise ValueError(message)

def stamp(value):
    require(isinstance(value, str) and value.endswith("Z"), "UTC timestamp ending Z required")
    result = datetime.fromisoformat(value[:-1] + "+00:00")
    return result

def unique(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "duplicate JSON key: " + key)
        result[key] = value
    return result

def validate(row, filename, now):
    require(type(row.get("schema")) is int and row["schema"] == 1, "schema must be 1")
    for key in ("run_id", "project", "task"):
        require(isinstance(row.get(key), str) and KEY.fullmatch(row[key]), "invalid " + key)
    require(row["run_id"] == filename, "run_id must match filename")
    state = row.get("state")
    require(state in ("none", "active", "held", "retired", "unknown"), "invalid state")
    def text(key, source=row):
        require(isinstance(source.get(key), str) and source[key].strip(), "missing " + key)
    if state == "none":
        text("reason")
        require(not row.get("object_id"), "none cannot conceal an object")
        return
    for key in ("host", "object_id", "owner"):
        text(key)
    if state != "retired":
        for key in ("reason", "next_action"):
            text(key)
        require(stamp(row.get("lease_until")) > now, "expired runtime lease; reconcile, never auto-delete")
        require(state != "unknown", "unknown outcome requires live reconciliation")
        return
    evidence = row.get("evidence", {})
    retirement = row.get("retirement", {})
    require(isinstance(evidence, dict) and isinstance(retirement, dict), "invalid evidence/retirement")
    text("reference", evidence)
    require(re.fullmatch(r"[0-9a-f]{64}", evidence.get("sha256", "")), "evidence SHA256 required")
    require(retirement.get("absent") is True, "retirement absence readback required")
    require(stamp(retirement.get("observed_at")) <= now, "future retirement observation")

def check(project, now=None):
    root = Path(project).resolve()
    directory = root / "docs/llm/runtime"
    now = now or datetime.now(timezone.utc)
    if not directory.exists():
        return ["runtime receipt coverage unknown; no declaration directory"], 0
    require(directory.resolve().is_relative_to(root), "receipt directory escapes project")
    files = sorted(directory.glob("*.json"))
    issues = []
    if not files:
        issues.append("runtime receipt coverage unknown; empty declaration directory")
    for path in files:
        try:
            require(not path.is_symlink(), "symlink receipt forbidden")
            row = json.loads(path.read_text(), object_pairs_hook=unique)
            require(isinstance(row, dict), "receipt must be object")
            validate(row, path.stem, now)
        except (ValueError, TypeError, KeyError, AttributeError, OSError) as error:
            issues.append(path.name + ": " + str(error))
    return issues, len(files)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--human", action="store_true")
    args = parser.parse_args()
    try:
        issues, count = check(args.project)
    except (ValueError, OSError) as error:
        issues, count = [str(error)], 0
    if args.human:
        print(("; ".join(issues) if issues else str(count)+" declared receipts valid") + "; undeclared runtime coverage unproven; no live discovery")
    else:
        print(json.dumps({"status": "WARN" if issues else "PASS", "checked": count,
                          "scope": "declared receipts valid only; undeclared coverage unproven", "issues": issues}))
    return (1 if args.strict else 3) if issues else 0

if __name__ == "__main__":
    raise SystemExit(main())
