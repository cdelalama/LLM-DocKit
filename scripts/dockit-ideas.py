#!/usr/bin/env python3
"""Validate project-owned idea continuity; never infer semantic completeness."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

INDEX = "docs/llm/IDEA_INDEX.json"
STATES = {"captured", "proposed", "accepted", "in_progress", "deferred",
          "rejected", "superseded", "transferred", "implemented"}
TERMINAL = {"rejected", "superseded", "transferred", "implemented"}
IDENTITY = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,99}\Z")


class Invalid(ValueError):
    pass


def require(test, message):
    if not test:
        raise Invalid(message)


def nonempty(value):
    return isinstance(value, str) and bool(value.strip())


def git(root, *args, optional=False):
    result = subprocess.run(["git", "-C", str(root), *args], capture_output=True,
                            text=True, encoding="utf-8", errors="replace")
    if result.returncode:
        if optional:
            return None
        raise Invalid("Git read failed: " + " ".join(args))
    return result.stdout


def relative(path):
    require(nonempty(path), "Reference needs a path")
    p = Path(path)
    require(not p.is_absolute() and ".." not in p.parts and ":" not in path
            and "\\" not in path and not path.startswith("-"), "Unsafe relative path: " + path)
    return path


def read(root, path, revision=None):
    relative(path)
    if revision:
        require(bool(re.fullmatch(r"[0-9a-f]{7,40}", revision)), "References require a pinned commit")
        git(root, "cat-file", "-e", revision + "^{commit}")
        return git(root, "show", revision + ":" + path)
    target = root / path
    require(target.resolve().is_relative_to(root.resolve()), "Reference escapes project")
    require(target.is_file(), "Missing file: " + path)
    return target.read_text(encoding="utf-8")


def load(text):
    def unique(pairs):
        out = {}
        for key, value in pairs:
            require(key not in out, "Duplicate JSON key: " + key)
            out[key] = value
        return out
    return json.loads(text, object_pairs_hook=unique)


class Checker:
    def __init__(self, root, baseline=None, projects=None):
        self.root = Path(root).resolve()
        self.projects = projects or {}
        self.warnings = []
        self.baseline_mode = "explicit" if baseline else "inferred"
        self.baseline = None
        if baseline:
            self.baseline = git(self.root, "rev-parse", "--verify", "--end-of-options",
                                baseline + "^{commit}").strip()
        else:
            head = git(self.root, "rev-parse", "--verify", "HEAD", optional=True)
            if head:
                # HEAD catches working-tree deletions; its parent also protects
                # an index deleted in the most recent committed change.
                clean = git(self.root, "status", "--porcelain", optional=True) == ""
                parent = git(self.root, "rev-parse", "--verify", "HEAD^", optional=True)
                self.baseline = (parent if clean and parent else head).strip()
                if clean and not parent:
                    self.warnings.append("Root commit has no predecessor; historical baseline unknown")
            else:
                self.warnings.append("Baseline unknown; structural inspection only")
            self.warnings.append("Inferred baseline; publication requires an explicit reviewed start revision")

    def ref(self, value):
        require(isinstance(value, dict), "Reference must be an object")
        require(set(value) <= {"path", "revision", "contains", "project"}, "Unknown reference field")
        relative(value.get("path"))
        if "contains" in value:
            require(nonempty(value["contains"]), "Empty reference anchor")
        project = value.get("project")
        root = self.root
        if project and project != self.project:
            require(IDENTITY.fullmatch(project), "Invalid reference project")
            if project not in self.projects:
                self.warnings.append("Unresolved cross-project reference: " + project + ":" + value["path"])
                return
            root = Path(self.projects[project]).resolve()
        content = read(root, value["path"], value.get("revision"))
        if "contains" in value:
            require(value["contains"] in content, "Missing anchor in " + value["path"] + ": " + value["contains"])

    def refs(self, values):
        require(isinstance(values, list) and values, "Nonempty references required")
        for value in values:
            self.ref(value)

    def register_ids(self, register, revision=None):
        require(isinstance(register, dict) and {"path", "pattern"} <= set(register)
                and set(register) <= {"path", "pattern", "moved_to"}, "Invalid register declaration")
        relative(register["path"])
        require(nonempty(register["pattern"]) and len(register["pattern"]) <= 200, "Invalid register pattern")
        pattern = re.compile(register["pattern"], re.MULTILINE)
        require(pattern.groups == 1, "Register pattern needs one identity group")
        content = (git(self.root, "show", revision + ":" + register["path"])
                   if revision else read(self.root, register.get("moved_to", register["path"])))
        return set(pattern.findall(content))

    def run(self):
        old_text = git(self.root, "show", self.baseline + ":" + INDEX, optional=True) if self.baseline else None
        path = self.root / INDEX
        if not path.exists():
            # Even an explicit baseline before adoption must not hide a latest
            # committed index that the working tree deleted.
            head_text = git(self.root, "show", "HEAD:" + INDEX, optional=True)
            parent_text = git(self.root, "show", "HEAD^:" + INDEX, optional=True)
            require(not old_text and not head_text and not parent_text, "Adopted idea index was deleted")
            return {"status": "not_adopted", "baseline": self.baseline, "warnings": self.warnings}
        data = load(read(self.root, INDEX))
        require(set(data) == {"schema", "project", "validator_sha256", "registers", "batches", "entries", "task_reconciliations"}, "Invalid index fields; priority belongs in HANDOFF/ROADMAP")
        require(data["validator_sha256"] == hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), "Installed idea helper differs from the adopted hash")
        require(data["schema"] == 1 and IDENTITY.fullmatch(data["project"]), "Invalid index identity")
        self.project = data["project"]
        self.projects.setdefault(self.project, str(self.root))
        for key in ["registers", "batches", "entries", "task_reconciliations"]:
            require(isinstance(data[key], list), "Expected array: " + key)
        batches = {}
        for batch in data["batches"]:
            require(set(batch) == {"id", "date", "sources", "excluded", "unknown", "coverage_claim", "remaining_backfill", "cursor"}, "Invalid batch fields")
            ident = batch["id"]
            require(isinstance(ident, str) and IDENTITY.fullmatch(ident) and ident not in batches, "Invalid/duplicate batch identity")
            require(bool(re.fullmatch(r"\d{4}-\d{2}-\d{2}", batch["date"])), "Invalid batch date")
            require(batch["coverage_claim"] == "declared_corpus_only", "Coverage must remain bounded")
            require(nonempty(batch["remaining_backfill"]) and nonempty(batch["cursor"]), "Batch needs remaining backfill and cursor")
            require(isinstance(batch["excluded"], list) and isinstance(batch["unknown"], list), "Coverage gaps must be arrays")
            self.refs(batch["sources"])
            batches[ident] = batch
        entries = {}
        for entry in data["entries"]:
            common = {"id", "record", "kind", "title", "origin", "batch", "owner", "recall_trigger"}
            native = {"state", "documentation_refs", "authority", "rationale", "successor", "evidence", "acceptance", "reopen_reason"}
            allowed = common | (native if entry.get("record") == "native" else {"ref"})
            require(common <= set(entry) and set(entry) <= allowed, "Unknown/missing entry fields (reference entries cannot own state/priority)")
            ident = entry["id"]
            require(isinstance(ident, str) and IDENTITY.fullmatch(ident) and ident not in entries, "Invalid/duplicate idea identity")
            require(entry["record"] in {"native", "reference"}, ident + ": invalid record type")
            require(entry["kind"] in {"operator_request", "agent_suggestion", "accepted_decision"}, ident + ": invalid kind")
            require(entry["batch"] in batches and entry["owner"] == self.project, ident + ": invalid batch/owner")
            require(nonempty(entry["title"]) and nonempty(entry["recall_trigger"]), ident + ": title/recall trigger required")
            origin = entry["origin"]
            require(isinstance(origin, dict) and set(origin) == {"date", "attribution", "sources"}, ident + ": invalid origin")
            require(nonempty(origin["date"]) and nonempty(origin["attribution"]), ident + ": origin requires date and attribution")
            self.refs(origin["sources"])
            if entry["record"] == "reference":
                self.ref(entry.get("ref"))
                # Origins are immutable historical evidence. A reference is
                # also a route to the current authority, even if it has a pin.
                live = dict(entry["ref"])
                live.pop("revision", None)
                self.ref(live)
            else:
                require(entry["kind"] != "accepted_decision", ident + ": decisions belong in their existing register")
                state = entry.get("state")
                require(state in STATES, ident + ": invalid state")
                self.refs(entry.get("documentation_refs"))
                if state in {"accepted", "in_progress", "rejected", "implemented"}:
                    require(nonempty(entry.get("authority")) and nonempty(entry.get("rationale")), ident + ": authority and rationale required")
                if state in {"superseded", "transferred"}:
                    require(nonempty(entry.get("rationale")), ident + ": successor rationale required")
                    self.ref(entry.get("successor"))
                if state == "implemented":
                    self.refs(entry.get("evidence"))
                    require(any(e.get("revision") and not e["path"].startswith("docs/")
                                and Path(e["path"]).suffix not in {".md", ".txt"}
                                for e in entry["evidence"]), ident + ": documentation alone is not implementation evidence")
                    a = entry.get("acceptance")
                    require(isinstance(a, dict) and set(a) == {"state", "reason"}
                            and a["state"] in {"verified", "pending", "not_applicable"}
                            and nonempty(a["reason"]), ident + ": explicit acceptance required")
            entries[ident] = entry
        registers = {}
        for register in data["registers"]:
            key = register["path"]
            require(key not in registers, "Duplicate register")
            registers[key] = self.register_ids(register)
        reconciliations = {}
        for item in data["task_reconciliations"]:
            require(set(item) == {"task", "ideas", "no_ideas_reason"}, "Invalid task reconciliation")
            task = relative(item["task"])
            require(task.startswith("docs/llm/work/") and task.endswith(".json"), "Invalid task path")
            require(task not in reconciliations and (self.root / task).is_file(), "Missing/duplicate task reconciliation")
            require(isinstance(item["ideas"], list) and all(i in entries for i in item["ideas"]), "Reconciliation references unknown idea")
            require(bool(item["ideas"]) != nonempty(item["no_ideas_reason"]), "Reconcile named ideas OR explain no new ideas")
            reconciliations[task] = item
        if old_text:
            old = load(old_text)
            require(data["project"] == old["project"], "Project identity changed")
            for previous in old["entries"]:
                ident = previous["id"]
                require(ident in entries, "Idea disappeared: " + ident)
                current = entries[ident]
                for key in ["id", "record", "kind", "batch", "owner"]:
                    require(current[key] == previous[key], ident + ": immutable field changed: " + key)
                for key in ["date", "attribution"]:
                    require(current["origin"][key] == previous["origin"][key], ident + ": origin changed")
                require(all(s in current["origin"]["sources"] for s in previous["origin"]["sources"]), ident + ": origin removed")
                if previous.get("state") in TERMINAL and current.get("state") != previous["state"]:
                    require(nonempty(current.get("reopen_reason")) and current.get("reopen_reason") != previous.get("reopen_reason"), ident + ": terminal transition needs a new reopen reason")
            for previous in old["registers"]:
                candidate = next((r for r in data["registers"] if r["path"] == previous["path"]), None)
                require(candidate and candidate["pattern"] == previous["pattern"], "Register declaration disappeared or pattern changed: " + previous["path"])
                prior_location = dict(previous)
                prior_location["path"] = previous.get("moved_to", previous["path"])
                lost = self.register_ids(prior_location, self.baseline) - self.register_ids(candidate)
                require(not lost, "Registered IDs disappeared: " + ", ".join(sorted(lost)))
            for batch in old["batches"]:
                require(batch["id"] in batches, "Coverage batch disappeared")
                for key in ["date", "sources", "excluded", "unknown", "coverage_claim"]:
                    require(batches[batch["id"]][key] == batch[key], "Historical batch provenance changed; add a new batch")
            for item in old["task_reconciliations"]:
                require(item["task"] in reconciliations, "Task reconciliation disappeared")
                require(set(item["ideas"]) <= set(reconciliations[item["task"]]["ideas"]), "Previously reconciled idea disappeared")
        # Adopted projects reconcile newly closed tasks. Old closed tasks keep
        # their historical meaning; closing documentation never closes ideas.
        work = self.root / "docs/llm/work"
        if self.baseline:
            old_tasks = git(self.root, "ls-tree", "-r", "--name-only", self.baseline, "docs/llm/work")
            for old_task in old_tasks.splitlines():
                if old_task.endswith(".json"):
                    require((self.root / old_task).is_file(), "Task record disappeared: " + old_task)
        for task in sorted(work.glob("*.json")) if work.exists() else []:
            value = load(task.read_text())
            require(isinstance(value, dict), "Task record must be an object")
            if value.get("state") != "closed":
                continue
            name = task.relative_to(self.root).as_posix()
            before = git(self.root, "show", self.baseline + ":" + name, optional=True) if self.baseline else None
            if not before or load(before).get("state") != "closed":
                require(name in reconciliations, "Newly closed task lacks idea reconciliation: " + name)
        return {"status": "warning" if self.warnings else "pass", "project": self.project,
                "baseline": self.baseline, "baseline_mode": self.baseline_mode, "entries": len(entries),
                "registered_ids": sum(map(len, registers.values())), "batches": len(batches),
                "warnings": sorted(set(self.warnings)), "coverage": "declared_corpus_only"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--baseline")
    parser.add_argument("--projects", type=Path, help="Private JSON mapping project IDs to checkouts")
    parser.add_argument("--list", action="store_true", help="Read-only idea/reference listing")
    parser.add_argument("--grep", default="", help="Case-insensitive recall search")
    args = parser.parse_args()
    try:
        checker = Checker(args.project, args.baseline, load(args.projects.read_text()) if args.projects else {})
        report = checker.run()
        if args.list or args.grep:
            data = load((args.project / INDEX).read_text())
            for entry in data["entries"]:
                if args.grep.casefold() in json.dumps(entry, ensure_ascii=False).casefold():
                    print(json.dumps(entry, ensure_ascii=False))
        print(json.dumps(report, ensure_ascii=False))
        return 3 if report["warnings"] else 0
    except (Invalid, OSError, ValueError, KeyError, TypeError, AttributeError, re.error) as error:
        print(json.dumps({"status": "fail", "error": str(error)}))
        return 1


if __name__ == "__main__":
    sys.exit(main())
