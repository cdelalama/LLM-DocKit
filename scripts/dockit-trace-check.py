#!/usr/bin/env python3
"""Check durable Trace records with one parse and invocation-local Git batches."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import sys

HASH = re.compile(r"`([0-9A-Fa-f]{7,40})`")
DATE = re.compile(r"^(?:- )?([0-9]{4}-[0-9]{2}-[0-9]{2}) - ")
FOOTER = re.compile(r"Trace: role=(executor|auditor|advisor); commits=[^;]+;( external=[^;]+;)? state=[^;]+; validation=[^;]+; next=.+")
SPACE = r"[ \t\r\v\f]"


def read_text(path):
    return path.read_bytes().decode("utf-8", "surrogateescape")


def hashes(text):
    return sorted({match.lower() for match in HASH.findall(text)})


def git(project, *args, input=None):
    result = subprocess.run(["git", "-C", str(project), *args], input=input,
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                            env=dict(os.environ, TZ="UTC"))
    return result.returncode, result.stdout.decode("utf-8", "surrogateescape").rstrip("\n")


class Commits:
    def __init__(self, project, requested, upstream):
        self.project = project
        self.upstream = upstream
        self.objects = {}
        self.metadata = {}
        self.remote = {}
        self.refs = []
        self.ancestors = set()
        self.has_upstream = False
        if not requested:
            return
        # Resolve both the quoted object and its peeled commit. An annotated tag
        # retains its original canonical short ID and legacy show output below.
        expressions = [expr for value in sorted(requested)
                       for expr in (value, value + "^{commit}")]
        rc, output = git(project, "cat-file", "--batch-check=%(objectname) %(objecttype)",
                         input=("\n".join(expressions) + "\n").encode())
        if rc or len(output.splitlines()) != len(expressions):
            raise ValueError("Git object batch failed")
        resolved = dict(zip(expressions, (line.split() for line in output.splitlines())))
        for value in sorted(requested):
            original, peeled = resolved[value], resolved[value + "^{commit}"]
            if len(peeled) == 2 and peeled[1] == "commit":
                self.objects[value] = (original[0], original[1], peeled[0])
        commits = sorted({peeled for _, kind, peeled in self.objects.values() if kind == "commit"})
        if commits:
            rc, output = git(project, "log", "--no-show-signature", "--no-walk=unsorted", "--stdin", "--abbrev=7",
                             "--format=%H%x00%h%x00%s%x00%cd%x00",
                             "--date=format-local:%Y-%m-%d %H:%M:%S UTC",
                             input=("\n".join(commits) + "\n").encode())
            fields = output.split("\0")
            if rc or fields[-1] or (len(fields) - 1) % 4:
                raise ValueError("Git metadata batch failed")
            for index in range(0, len(fields) - 1, 4):
                oid, short, subject, seconds = fields[index:index + 4]
                self.metadata[oid.lstrip("\n")] = (short, subject, seconds, seconds[:-7] + " UTC")
        rc, refs = git(project, "for-each-ref", "--format=%(refname)", "refs/remotes/origin")
        if rc:
            raise ValueError("Git remote reference listing failed")
        self.refs = refs.splitlines()
        upstream_ref = "refs/remotes/origin/" + upstream
        self.has_upstream = upstream_ref in self.refs
        if self.has_upstream:
            rc, ancestors = git(project, "rev-list", upstream_ref)
            if rc:
                raise ValueError("Git upstream ancestry traversal failed")
            self.ancestors = set(ancestors.splitlines())

    def info(self, value):
        item = self.objects.get(value)
        if item is None:
            return None
        original, kind, peeled = item
        if kind == "commit":
            return self.metadata[peeled]
        if original not in self.metadata:
            # Preserve the uncommon annotated-tag spelling accepted by the old
            # shell check, including git show's tag header and message.
            _, short = git(self.project, "rev-parse", "--short=7", value)
            _, subject = git(self.project, "show", "--no-show-signature", "-s", "--format=%s", value)
            _, seconds = git(self.project, "show", "--no-show-signature", "-s", "--format=%cd", "--date=format-local:%Y-%m-%d %H:%M:%S UTC", value)
            _, minutes = git(self.project, "show", "--no-show-signature", "-s", "--format=%cd", "--date=format-local:%Y-%m-%d %H:%M UTC", value)
            self.metadata[original] = short, subject, seconds, minutes
        return self.metadata[original]

    def other_remote(self, value):
        peeled = self.objects[value][2]
        if peeled not in self.remote:
            rc, refs = git(self.project, "for-each-ref", "--format=%(refname)",
                           "--contains=" + peeled, "refs/remotes/origin")
            self.remote[peeled] = next((ref for ref in refs.splitlines()
                                       if not ref.endswith("/HEAD")), None) if not rc else None
        return self.remote[peeled]

    def validate(self, value, context, text, require_subject, errors, warnings):
        info = self.info(value)
        if info is None:
            errors.append(f"{context} references commit {value}, but git cannot resolve it")
            return
        short, subject, seconds, minutes = info
        if short and short not in text:
            errors.append(f"{context} references {value} but does not contain canonical short hash {short}")
        # grep -F with a multiline pattern accepts any pattern line, including
        # empty lines in git show's annotated-tag output.
        contains = lambda pattern: any(line in text for line in pattern.split("\n"))
        if require_subject:
            if subject and not contains(subject):
                errors.append(f"{context} target {short} is missing commit subject: {subject}")
            if seconds and not contains(seconds) and not contains(minutes):
                errors.append(f"{context} target {short} is missing commit time: {seconds} (or {minutes})")
        if self.has_upstream and self.objects[value][2] not in self.ancestors:
            remote = self.other_remote(value)
            if remote:
                warnings.append(f"{context} target {short} is on remote ref {remote}, not origin/{self.upstream}")
            else:
                errors.append(f"{context} target {short} is not an ancestor of origin/{self.upstream} or any origin/* remote ref")


def check(args):
    errors, warnings = [], []
    handoff, history = args.project / "docs/llm/HANDOFF.md", args.project / "docs/llm/HISTORY.md"
    anchor = ""
    if handoff.is_file():
        capture, lines = False, []
        for line in read_text(handoff).split("\n"):
            if re.fullmatch(r"##" + SPACE + r"+Trace Anchor" + SPACE + "*", line):
                capture = True
                continue
            if capture and re.match(r"##" + SPACE + "+", line):
                break
            if capture:
                lines.append(line)
        anchor = "\n".join(lines).rstrip("\n")
        if not anchor:
            errors.append("HANDOFF.md is missing required ## Trace Anchor section")
    else:
        errors.append("HANDOFF.md not found")
    entries = []
    if history.is_file():
        for line in read_text(history).split("\n"):
            date = DATE.match(line)
            if date and date[1] >= args.since:
                quoted = hashes(line)
                if quoted:
                    entries.append((date[1], line, quoted))
    anchor_hashes = hashes(anchor)
    requested = set(anchor_hashes)
    # Externally namespaced hashes do not need local Git resolution. Keeping
    # them in this cheap object batch does not affect their validation outcome.
    requested.update(value for _, _, values in entries for value in values)
    commits = Commits(args.project, requested, args.upstream)
    if anchor:
        required = [(r"Role:" + SPACE + r"*(executor|auditor|advisor)", "Role: executor|auditor|advisor"),
                    (r"(Current target|Current audit target|Trace target|Subject):", "Trace target/Subject"),
                    (r"(State verified|Repo state):", "State verified/Repo state"),
                    (r"Validation:", "Validation"), (r"(Next gate|Next):", "Next gate/Next")]
        for expression, label in required:
            if not re.search(expression, anchor):
                errors.append("Trace Anchor missing " + label)
        for value in anchor_hashes:
            commits.validate(value, "HANDOFF Trace Anchor", anchor, True, errors, warnings)
        if args.reject_current and re.search(r"(Current target|Current audit target):", anchor):
            errors.append("trace_protocol.reject_current_anchor_label=true disallows HANDOFF Trace Anchor labels that imply currency; use Subject: or Trace target: instead")
    if not history.is_file():
        errors.append("HISTORY.md not found")
    for date, entry, quoted in entries:
        if not FOOTER.search(entry):
            errors.append(f"HISTORY entry {date} references backticked commit hash(es) but lacks inline Trace footer")
            continue
        match = re.match(r".*Trace: role=[^;]*; commits=([^;]*); state=.*", entry)
        field = match[1] if match else entry
        if "; external=" in field:
            match = re.match(r".*Trace: role=[^;]*; commits=([^;]*); external=.*", entry)
            field = match[1] if match else entry
        local = "," + field.replace(" ", "") + ","
        external_match = re.match(r".*; external=([^;]*); state=.*", entry)
        external = set()
        if external_match and external_match[1]:
            references = external_match[1].split(",")
            # Shell IFS splitting retains leading/interior empty fields and
            # omits exactly the empty field after the last delimiter.
            if references[-1] == "":
                references.pop()
            for reference in references:
                reference = reference.replace(" ", "")
                if not re.fullmatch(r"[A-Za-z0-9._/-]+@[0-9A-Fa-f]{7,40}", reference):
                    errors.append(f"HISTORY entry {date} has invalid external= reference {reference} (expected repo@hash)")
                    continue
                value = reference.rsplit("@", 1)[1].lower()
                if value not in quoted:
                    errors.append(f"HISTORY entry {date} external= declares {reference} but the exact hash is not backtick-quoted in the entry")
                external.add(value)
        for value in quoted:
            if value in external:
                if "," + value + "," in local:
                    errors.append(f"HISTORY entry {date} declares {value} as both local commits= and external=")
                continue
            info = commits.info(value)
            short = info[0] if info else value
            if "," + value + "," not in local and "," + short + "," not in local:
                errors.append(f"HISTORY Trace footer commits= does not include referenced hash {value}")
            commits.validate(value, "HISTORY Trace footer", entry, False, errors, warnings)
    if errors:
        return "FAIL", "; ".join(errors)
    if warnings:
        return "WARN", "; ".join(warnings)
    return "PASS", "Trace Protocol durable contract satisfied since " + args.since


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="backslashreplace")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--since", required=True)
    parser.add_argument("--upstream", required=True)
    parser.add_argument("--reject-current", action="store_true")
    args = parser.parse_args()
    try:
        status, message = check(args)
    except (OSError, ValueError, KeyError) as exc:
        status, message = "FAIL", "Trace checker failed: " + str(exc)
    print(status + "|" + message)


if __name__ == "__main__":
    main()
