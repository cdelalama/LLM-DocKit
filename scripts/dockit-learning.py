#!/usr/bin/env python3
"""Check declared operator-correction cases without claiming chat completeness."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys


def check(root):
    path = root / "docs/llm/FAILURE_LEARNING.json"
    if not path.exists():
        return ["SKIP: no adopted failure-learning register"]
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise ValueError(f"invalid failure-learning register: {exc}") from exc
    if (not isinstance(data, dict) or set(data) != {"schema", "cases"}
            or type(data["schema"]) is not int or data["schema"] != 1
            or not isinstance(data["cases"], list)):
        raise ValueError("register requires schema 1 and cases array")
    ids = set()
    for item in data["cases"]:
        if not isinstance(item, dict):
            raise ValueError("each case must be an object")
        required = {"id", "observed", "consequence", "cause_status", "cause",
                    "status", "corrective_action", "owner", "verification",
                    "source_refs", "prevention_refs", "adoption_revision",
                    "coverage_limit"}
        if set(item) != required:
            raise ValueError(f"{item.get('id', 'case')}: fields differ from schema")
        ident = item["id"]
        if not isinstance(ident, str) or not re.fullmatch(r"FL-[0-9]{3,}", ident) or ident in ids:
            raise ValueError("case IDs must be unique FL-nnn values")
        ids.add(ident)
        for field in ("observed", "consequence", "cause", "corrective_action", "owner", "verification", "coverage_limit"):
            if not isinstance(item[field], str) or not item[field].strip():
                raise ValueError(f"{ident}: {field} must explain the case")
        if not isinstance(item["cause_status"], str) or item["cause_status"] not in {"known", "hypothesis", "unknown"}:
            raise ValueError(f"{ident}: invalid cause_status")
        if not isinstance(item["status"], str) or item["status"] not in {"open", "mitigated", "closed"}:
            raise ValueError(f"{ident}: invalid status")
        for field in ("source_refs", "prevention_refs"):
            refs = item[field]
            if not isinstance(refs, list) or any(not isinstance(ref, str) for ref in refs):
                raise ValueError(f"{ident}: {field} must be a path list")
            if item["status"] == "closed" and not refs:
                raise ValueError(f"{ident}: closed case requires {field}")
            for ref in refs:
                candidate = (root / ref).resolve()
                try:
                    candidate.relative_to(root.resolve())
                    inside = True
                except ValueError:
                    inside = False
                if not inside or not candidate.is_file():
                    raise ValueError(f"{ident}: {field} path missing or outside project: {ref}")
        if item["status"] == "closed" and item["cause_status"] != "known":
            raise ValueError(f"{ident}: closed case requires an established cause")
        adoption = item["adoption_revision"]
        if adoption is not None and (not isinstance(adoption, str) or
                                     not re.fullmatch(r"[0-9a-f]{7,40}", adoption)):
            raise ValueError(f"{ident}: adoption_revision must be a commit hash or null")
        if item["status"] == "closed" and adoption is None:
            raise ValueError(f"{ident}: closed case requires an adoption revision")
        if item["status"] == "closed":
            for ref in item["prevention_refs"]:
                try:
                    result = subprocess.run(
                        ["git", "-C", str(root), "cat-file", "-e", f"{adoption}:{ref}"],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                        check=False)
                except OSError as exc:
                    raise ValueError(f"{ident}: cannot check adoption commit: {exc}") from exc
                if result.returncode:
                    raise ValueError(f"{ident}: prevention artifact absent at adoption revision: {ref}")
    return [f"PASS: {len(ids)} declared cases structurally checked; conversation coverage is not inferred"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    args = parser.parse_args()
    try:
        for line in check(args.project.resolve()):
            print(line)
    except ValueError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
