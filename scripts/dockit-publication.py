#!/usr/bin/env python3
"""Read-only publication closeout. Offline inspection never proves publication.

Run --require-published once after committing and pushing: verifies a clean
checkout and exact HEAD on the remote-advertised default branch. No fetch,
commit, push, lock file, receipt, or background job is created by this helper.
"""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import sys

sys.dont_write_bytecode = True


def inspect(project, require_published=False):
    env = {**os.environ, "GIT_OPTIONAL_LOCKS": "0", "GIT_TERMINAL_PROMPT": "0"}

    def git(*args, timeout=10):
        p = subprocess.Popen(["git", "-C", str(project), *args], env=env,
                             stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE, start_new_session=(os.name == "posix"))
        try:
            output, _ = p.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            if os.name == "posix":
                try:
                    os.killpg(p.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
            else:
                # Retire this owned Git family; never enumerate unrelated jobs.
                subprocess.run(["taskkill", "/PID", str(p.pid), "/T", "/F"],
                               stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL, timeout=5)
            p.kill() if p.poll() is None else None
            p.communicate()
            raise
        if p.returncode:
            # Git diagnostics can include credential-bearing remote URLs.
            raise ValueError("Git %s failed (exit %d)" % (args[0], p.returncode))
        return output

    head = git("rev-parse", "--verify", "HEAD").decode().strip()
    status = git("status", "--porcelain=v1", "-z", "--untracked-files=all",
                 "--ignore-submodules=none")
    result = {"state": "pending", "head": head, "dirty": bool(status),
              "remote_verified": False, "problems": []}
    if status:
        result["problems"].append("Uncommitted or untracked work remains; preserve ownership and publish task work")
    if require_published:
        fetch_urls = git("remote", "get-url", "--all", "origin").splitlines()
        push_urls = git("remote", "get-url", "--push", "--all", "origin").splitlines()
        if len(fetch_urls) != 1 or push_urls != fetch_urls:
            raise ValueError("Origin fetch/push destinations differ or are multiple; qualify the authoritative publication route")
        advertised = git("ls-remote", "--symref", "--", "origin", "HEAD", timeout=20).decode("utf-8", "replace")
        branch, remote_head = None, None
        for line in advertised.splitlines():
            fields = line.split()
            if len(fields) == 3 and fields[0] == "ref:" and fields[2] == "HEAD":
                branch = fields[1]
            elif len(fields) == 2 and fields[1] == "HEAD":
                remote_head = fields[0]
        if not branch or not branch.startswith("refs/heads/") or not remote_head:
            raise ValueError("Origin did not advertise its default branch and HEAD")
        result.update(remote_verified=True, target_branch=branch, remote_head=remote_head)
        if head != remote_head:
            result["problems"].append("HEAD differs from the live origin default branch; reconcile and publish without force")
    else:
        try:
            upstream = git("rev-parse", "--verify", "@{upstream}").decode().strip()
            result["cached_upstream_head"] = upstream
            if head != upstream:
                result["problems"].append("HEAD differs from the cached upstream; publication or synchronization remains")
        except ValueError:
            result["problems"].append("No usable upstream; publication is unverified")
    if head != git("rev-parse", "--verify", "HEAD").decode().strip() or status != git(
            "status", "--porcelain=v1", "-z", "--untracked-files=all", "--ignore-submodules=none"):
        result["problems"].append("Checkout changed during inspection; repeat at closeout")
    if not result["problems"]:
        result["state"] = "published" if require_published else "locally_synchronized"
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", default=".")
    parser.add_argument("--require-published", action="store_true",
                        help="after push, require clean HEAD equal to live origin default branch")
    parser.add_argument("--human", action="store_true")
    args = parser.parse_args()
    try:
        result = inspect(Path(args.project).resolve(), args.require_published)
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        detail = "Git command timed out" if isinstance(error, subprocess.TimeoutExpired) else str(error)
        result = {"state": "unavailable", "remote_verified": False, "problems": [detail]}
    if args.human:
        print(result["state"] + ": " + ("; ".join(result["problems"]) or
              ("clean HEAD equals live origin default branch" if result["remote_verified"]
               else "clean HEAD matches cached upstream; live publication not checked")))
    else:
        print(json.dumps(result, sort_keys=True))
    return (1 if args.require_published else 3) if result["problems"] else 0


if __name__ == "__main__":
    sys.exit(main())
