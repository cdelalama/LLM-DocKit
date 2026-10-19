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
# A reviewed, finite migration registry, not a user-selectable bypass.
TEMPLATE_IMPORTS = {'2f4ba1c91cc2ac0dd49682089bdf0916b6988138': {'project': 'house-docs', 'admission': 'e20ba680d65790e07f0844df1eb064be4f623902', 'contract_sha256': 'b68e01ca5b8c09829d6c29c1075f39452885ad9bfc70f75cef228a3c38fda64a', 'template_revision': '71a7d2a838d69d7a2897e35f587512628504f2b5', 'files': {'docs/llm/work/actions-efficiency-20261014.json': 'c15f60224b7364b8d079b28970f6e5ef00f7b318f53c2ad7801889548a61dc24', 'docs/llm/work/dossier-language-20260930.json': '5c130ed46c68694d0c0b506cf43b9a7081d5263794c6df1b1f6ede8e40bf0817', 'docs/llm/work/idea-continuity-20261007.json': 'df58cf44c2d1c98853677d7da68b7370fccd87748433ee19c7321f5c658b0674', 'docs/llm/work/operator-clarity-20261001.json': 'e051f46d1a4bb83cf6897c982f4dc2c3f3385e389877ea20e45af64e448ee6d3', 'docs/llm/work/project-protocol-20261013.json': '87b14363edb5734c276749a1e0cde09c138272119eeba8f6e1c7a45f397f7e28', 'docs/llm/work/wt_18575d2cdc8bfde9.json': '3155f5fcbf2451cf6719b2db76e6d8b50bd71c5f79edf76590bdb6691114a791', 'docs/llm/work/wt_592e417f602230b2.json': '9e38a7f98d362f626e074be27b311eff436f8da559d29a87ca07383f78fc651e', 'docs/llm/work/wt_66fcfc6df8bce34c.json': 'a3925f77f73c01d25fb9b26e58d881b5d27d800ac741b5147779e7359a0c770e', 'docs/llm/work/wt_aa94ab3e16782f49.json': '3550c29a48d43f08232aa88e6be542937a40b0680b7802cb2f6204bbdb81d49e', 'docs/llm/work/wt_c96e20d1843453b7.json': 'c4273c8bc3f4215302e4b37383f11272db0bec6c823fbc1ef409d5616e5efc1d', 'docs/llm/work/wt_ecf27ef256cff43e.json': '0929c81a02ecd494e6a6fc816526c47bfa1f1b1a2623946b6c6e1c8b18cefd3e', 'docs/llm/work/wt_f1cbeb73311127f3.json': '8a60f1d114fb5094e0b6c763d45620f0ae85a8cf40a937efd7892c34f7c89710', 'docs/llm/work/wt_f514a0c9d97112c2.json': '31c3aec9580209f579a2b8f34c41cbdd52a670479e13a7f36f3ed056f60bff92', 'docs/llm/IDEA_INDEX.json': '2005234bd983b62a437ec24a83b094d3b277d9810ad031d048fab116aa1e8dcf', 'docs/llm/WORK_INDEX.md': '8a77657d91d96d63331ae52ecd1bcf0fffc584a626bcede1052a39add4466f27'}}}
REPAIR = "docs/llm/TEMPLATE_IMPORT_REPAIR.json"
ARCHIVE = "docs/archive/template-import/"

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


def exact_bytes(root, path, revision=None):
    # Validate containment and commit syntax through the ordinary reader first.
    read(root, path, revision)
    if revision:
        return subprocess.check_output(["git", "-C", str(root), "show", revision + ":" + path])
    return (root / path).read_bytes()


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
        self.requested_baseline = baseline
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

    def template_import(self, data, old_text):
        """Recognize only registered contaminated births; preserve every old byte."""
        receipt_path = self.root / REPAIR
        receipt_history = git(self.root, "log", "--full-history", "--format=%H", "HEAD", "--", REPAIR, optional=True)
        require(receipt_path.exists() or not receipt_history, "Template repair receipt disappeared")
        if not receipt_path.exists():
            return old_text, set()
        receipt = load(read(self.root, REPAIR))
        require(set(receipt) == {"schema", "root", "admission", "project", "template_revision", "policy_revision", "review_manifest_sha256", "files"}, "Invalid template repair receipt")
        roots = git(self.root, "rev-list", "--max-parents=0", "HEAD").splitlines()
        require(len(roots) == 1 and receipt["root"] == roots[0], "Repair requires the single registered root")
        spec = TEMPLATE_IMPORTS.get(roots[0])
        require(spec is not None, "Unregistered template import; no automatic exception")
        require(receipt["schema"] == 1 and receipt["project"] == spec["project"] == data["project"] != "LLM-DocKit", "Invalid repair project")
        for key in ["admission", "template_revision", "files"]:
            require(receipt[key] == spec[key], "Repair registry mismatch: " + key)
        require(bool(re.fullmatch(r"[0-9a-f]{40}", receipt["policy_revision"])) and bool(re.fullmatch(r"[0-9a-f]{64}", receipt["review_manifest_sha256"])), "Repair needs pinned policy and review evidence")
        contract_path = ".forgeos/project-birth.json"
        contract_bytes = exact_bytes(self.root, contract_path, spec["admission"])
        require(hashlib.sha256(contract_bytes).hexdigest() == spec["contract_sha256"], "Birth contract differs from registered admission")
        contract = load(contract_bytes)
        require(contract["project"]["name"] == data["project"] and contract["origin"]["created_by"] == "ForgeOS" and contract["origin"]["workflow"] == "/new-homelab-project" and contract["birth"]["retrofit"] is False, "Only independently registered new creation is eligible")
        current_contract = load(read(self.root, contract_path))
        require(current_contract["project"]["name"] == data["project"] and current_contract["birth"]["retrofit"] is False, "Current birth identity changed")
        transitions = git(self.root, "log", "--full-history", "--format=%H", "--diff-filter=A", "HEAD", "--", REPAIR).splitlines()
        require(len(transitions) <= 1, "Multiple repair transitions")
        transition = transitions[0] if transitions else None
        parent = git(self.root, "rev-parse", transition + "^" ).strip() if transition else git(self.root, "rev-parse", "HEAD").strip()
        require(git(self.root, "rev-list", "--count", spec["admission"] + ".." + parent).strip() == "0" and parent == spec["admission"], "Repair must be the first change after registered admission")
        require(self.baseline is not None, "Repair requires a known baseline")
        born = load(read(self.root, INDEX, roots[0]))
        require(born["project"] == "LLM-DocKit", "Birth did not import template identity")
        archived = {p.relative_to(self.root / ARCHIVE).as_posix() for p in (self.root / ARCHIVE).rglob("*") if p.is_file()}
        require(archived == set(spec["files"]), "Archive set differs from registered import")
        removed = set()
        for path, expected in spec["files"].items():
            born_bytes = exact_bytes(self.root, path, roots[0])
            require(hashlib.sha256(born_bytes).hexdigest() == expected, "Registered birth hash mismatch: " + path)
            changes = git(self.root, "log", "--format=%H", roots[0] + ".." + parent, "--", path).strip()
            require(not changes, "Imported record changed before repair: " + path)
            archive_path = ARCHIVE + path
            require(hashlib.sha256(exact_bytes(self.root, archive_path)).hexdigest() == expected, "Frozen archive changed: " + path)
            if transition:
                require(hashlib.sha256(exact_bytes(self.root, archive_path, transition)).hexdigest() == expected, "Repair commit archive differs: " + path)
            if path.startswith("docs/llm/work/"):
                require(not (self.root / path).exists(), "Foreign work record remains live: " + path)
                removed.add(path)
        if transition:
            require(read(self.root, REPAIR) == read(self.root, REPAIR, transition), "Frozen repair receipt changed")
            actual_deleted = set(git(self.root, "diff", "--no-renames", "--name-only", "--diff-filter=D", parent, transition).splitlines())
        else:
            actual_deleted = set(git(self.root, "diff", "HEAD", "--no-renames", "--name-only", "--diff-filter=D").splitlines())
        require(actual_deleted == removed, "Repair deleted files outside the exact imported work set")
        # The admission may already own real decisions even though its index
        # is foreign. Preserve their IDs across this one-time identity repair.
        boundary = load(read(self.root, INDEX, transition)) if transition else data
        for register in born["registers"] + boundary["registers"]:
            prior = git(self.root, "show", spec["admission"] + ":" + relative(register["path"]), optional=True)
            if prior is None:
                continue  # A genuinely new child register has no prior IDs.
            pattern = re.compile(register["pattern"], re.MULTILINE)
            prior_ids = set(pattern.findall(prior))
            replacement = next((v for v in boundary["registers"] if v["path"] == register["path"]), register)
            destination = replacement.get("moved_to", replacement["path"])
            retained = read(self.root, destination, transition)
            require(prior_ids <= set(pattern.findall(retained)), "Admission register IDs disappeared during repair: " + register["path"])
        if self.baseline in {roots[0], spec["admission"]}:
            # Explicit, reported transition boundary. Afterwards all normal
            # anti-deletion checks compare with the first child-owned index.
            if transition:
                old_text = read(self.root, INDEX, transition)
                self.baseline = transition
                removed = set()
            else:
                old_text = None
        else:
            require(transition is not None, "Unpublished repair needs the reviewed admission baseline")
            require(git(self.root, "merge-base", self.baseline, transition).strip() == transition, "Baseline predates the registered repair")
            removed = set()
        self.repair_transition = transition or "working-tree-candidate"
        return old_text, removed

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
        old_text, archived_tasks = self.template_import(data, old_text)
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
                if old_task.endswith(".json") and old_task not in archived_tasks:
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
                "baseline": self.baseline, "requested_baseline": self.requested_baseline, "baseline_mode": self.baseline_mode, "template_repair": getattr(self, "repair_transition", None), "entries": len(entries),
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
