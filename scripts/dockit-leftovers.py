#!/usr/bin/env python3
"""Report task workspaces and branches left behind after publication.

Read-only and offline. Exit 0 PASS, 3 WARN, 1 FAIL.

FAIL only when the host workspace ledger (ForgeOS `task-workspace status`)
shows a closed workspace created under the clean-up rule that is still not
retired. Git-only evidence (a linked worktree or branch already contained in the
fetched origin default branch) is a WARN candidate: Git cannot tell an active,
just-created workspace from a forgotten one.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

sys.dont_write_bytecode = True


def git(root, *args):
    p = subprocess.run(['git', '-C', str(root), *args], capture_output=True, text=True,
                       env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'})
    if p.returncode != 0:
        raise RuntimeError('git %s failed: %s' % (args[0], p.stderr.strip()))
    return p.stdout


def ok(root, *args):
    return subprocess.run(['git', '-C', str(root), *args], capture_output=True, text=True).returncode == 0


def worktrees(root):
    rows, row = [], {}
    for field in git(root, 'worktree', 'list', '--porcelain', '-z').split('\0'):
        if not field:
            if row:
                rows.append(row); row = {}
        else:
            key, _, value = field.partition(' ')
            row[key] = value
    if row:
        rows.append(row)
    return rows


def default_ref(root):
    if ok(root, 'symbolic-ref', '-q', 'refs/remotes/origin/HEAD'):
        return git(root, 'symbolic-ref', '-q', 'refs/remotes/origin/HEAD').strip()
    for ref in ('refs/remotes/origin/main', 'refs/remotes/origin/master'):
        if ok(root, 'show-ref', '--verify', '--quiet', ref):
            return ref
    return None


def ledger_file(root):
    """Read the ForgeOS host ledger directly through its admitted canonical path."""
    try:
        policy = json.loads(Path(os.environ.get('DOCKIT_WORKSPACE_POLICY', Path.home() / '.config/forgeos/workspaces.json')).read_text())
        projects = json.loads(Path(policy['admission_file']).read_text())['projects']
        keys = [k for k, v in projects.items() if Path(v['path']).resolve() == root]
        if len(keys) != 1:
            return None
        return json.loads((Path(policy['state_root']) / (keys[0] + '.json')).read_text())
    except (OSError, ValueError, KeyError, TypeError):
        return None


def ledger(root):
    """Return (data, limit). No command: not a managed host. A failing command: coverage unknown."""
    command = os.environ.get('DOCKIT_TASK_WORKSPACE') or shutil.which('task-workspace')
    if not command:
        return None, None
    try:
        p = subprocess.run([command, 'status', '--project', str(root)], capture_output=True, text=True, timeout=60)
        if p.returncode != 0:
            data = ledger_file(root)  # status needs Git; the host ledger file does not.
            if data is None:
                return None, 'workspace ledger unavailable: ' + (p.stderr.strip().splitlines() or ['unknown'])[-1]
        else:
            data = json.loads(p.stdout)
        if type(data) is not dict or type(data.get('items')) is not dict:
            return None, 'workspace ledger returned an unexpected shape'
        return data, None
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        return None, 'workspace ledger unreadable: %s' % error


def git_candidates(root, current):
    ref = default_ref(root)
    if not ref:
        raise RuntimeError('no fetched origin default branch')
    default_branch = 'refs/heads/' + ref.split('refs/remotes/origin/', 1)[-1]
    merged = set(git(root, 'rev-list', ref).split())
    rows = worktrees(root)
    in_use = {r['branch'] for r in rows if r.get('branch')} | {default_branch}
    found = []
    for r in rows[1:]:
        path = Path(r['worktree']).resolve()
        if path != current and r.get('HEAD') in merged:
            found.append('worktree:' + (r.get('branch', '').removeprefix('refs/heads/') or path.name))
    for line in git(root, 'for-each-ref', '--format=%(refname) %(objectname)', 'refs/heads', 'refs/remotes/origin').splitlines():
        name, oid = line.split(' ')
        short = 'refs/heads/' + name.removeprefix('refs/remotes/origin/') if name.startswith('refs/remotes/origin/') else name
        if name.endswith('/HEAD') or short in in_use or oid not in merged:
            continue
        found.append('branch:' + name.removeprefix('refs/'))
    primary = Path(rows[0]['worktree']).resolve() if rows else None
    return found, primary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', default='.')
    root = Path(parser.parse_args().project).resolve()
    limits, candidates, primary, current = [], [], None, root
    try:
        current = Path(git(root, 'rev-parse', '--show-toplevel').strip()).resolve()
        candidates, primary = git_candidates(root, current)
    except (RuntimeError, OSError, ValueError, IndexError, KeyError) as error:
        limits.append('Git leftover coverage unknown (%s)' % error)
    # Each source is evaluated independently: a confirmed violation fails even when Git is unreadable.
    data, limit = ledger(root)
    if limit:
        limits.append(limit)
    new, legacy, self_closed = [], 0, False
    for ident, item in sorted((data or {}).get('items', {}).items()):
        try:
            if item['record']['state'] != 'closed' or item.get('phase') == 'retired':
                continue
            if Path(item['path']).resolve() == current and current != primary:
                self_closed = True  # A session cannot remove the checkout it runs in.
            elif item.get('created'):
                new.append(ident)
            else:
                legacy += 1
        except (KeyError, TypeError, OSError):
            limits.append('ledger item %s unreadable' % ident)
    hint = 'retire with task-workspace retire --project %s --task ID (or retire-branches)' % root.name
    if new:
        print('; '.join(['%d closed workspace(s) not retired: %s; %s' % (len(new), ', '.join(new), hint)] + limits)); return 1
    notes = []
    if candidates or legacy:
        notes.append('%d merged worktree/branch candidate(s) and %d legacy closed workspace(s) to retire; %s' % (len(candidates), legacy, hint))
    if self_closed:
        notes.append('this closed task checkout must be retired from the primary after the session ends')
    if notes or limits:
        print('; '.join(notes + limits)); return 3
    print('No workspaces or branches left behind'); return 0


if __name__ == '__main__':
    sys.exit(main())
