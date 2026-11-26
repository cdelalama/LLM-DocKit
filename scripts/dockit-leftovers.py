#!/usr/bin/env python3
"""Report task workspaces, branches and residue files left behind.

Read-only and offline. Exit 0 PASS, 3 WARN, 1 FAIL. Nothing is ever deleted.

FAIL only when the host workspace ledger (ForgeOS `task-workspace status`)
shows a closed workspace created under the clean-up rule that is still not
retired. Git-only evidence (a linked worktree or branch already contained in the
fetched origin default branch) is a WARN candidate: Git cannot tell an active,
just-created workspace from a forgotten one.

Residue files (docs/LEAVE_NO_RESIDUE.md) are also a WARN, never a FAIL: files in
this checkout that are tracked, or untracked and not git-ignored, and whose name
matches a backup/temporary pattern (RESIDUE below). The warning asks for origin
and authorization first: the name alone does not say who made the file. A file
kept on purpose is listed by exact repository-relative path (quote a path that
contains " #"), with its reason as a comment, under a top-level
`residue_allow:` list in .dockit-config.yml:

    residue_allow:
      - fixtures/legacy.orig   # parser input fixture, owner: project
"""
import argparse
from fnmatch import fnmatchcase
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

sys.dont_write_bytecode = True

RESIDUE = ('*.bak', '*.orig', '*.rej', '*.tmp', '*~', '*.swp', '*.before', '*.before-*', '*.incomplete-*')


def git(root, *args):
    p = subprocess.run(['git', '-C', str(root), *args], capture_output=True, encoding='utf-8', errors='surrogateescape',
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


def residue_allowed(root):
    """Exact paths under the top-level residue_allow list of .dockit-config.yml."""
    allowed, inside = set(), False
    try:
        lines = (root / '.dockit-config.yml').read_text(encoding='utf-8', errors='surrogateescape').splitlines()
    except OSError:
        return allowed
    for line in lines:
        item = line.strip()
        if line.split(' #')[0].rstrip() == 'residue_allow:':
            inside = True
        elif inside and item.startswith('- '):
            item = item[2:].strip()
            if item[:1] in ('"', "'"):  # A quoted path may contain " #".
                allowed.add(item[1:].split(item[0])[0])
            else:
                allowed.add(item.split(' #')[0].strip())
        elif item and not item.startswith('#'):
            inside = False
    return allowed


def residue_files(root):
    """Tracked, or untracked and not ignored, files whose name is a backup/temporary pattern.

    The NUL-delimited listing is read as a byte stream: memory stays bounded and
    a name that is not valid UTF-8 is still listed (surrogateescape)."""
    allowed, found, tail = residue_allowed(root), set(), b''
    p = subprocess.Popen(['git', '-C', str(root), 'ls-files', '-z', '--cached', '--others', '--exclude-standard'],
                         stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'})
    try:
        for chunk in iter(lambda: p.stdout.read(65536), b''):
            *names, tail = (tail + chunk).split(b'\0')
            for raw in names:
                path = raw.decode('utf-8', 'surrogateescape')
                if path not in allowed and any(fnmatchcase(path.rsplit('/', 1)[-1], pattern) for pattern in RESIDUE):
                    found.add(path)
    finally:
        p.stdout.close()
        if p.wait() != 0:
            raise RuntimeError('git ls-files failed (exit %d)' % p.returncode)
    return sorted(found)


def shown(name):
    """A file name as printable text; control and undecodable characters are escaped."""
    return ''.join(c if c.isprintable() else c.encode('unicode_escape').decode('ascii') for c in name)


def emit(text):
    """Print in the output encoding without ever raising on an unencodable character."""
    encoding = sys.stdout.encoding or 'utf-8'
    sys.stdout.write(text.encode(encoding, 'backslashreplace').decode(encoding, 'replace') + '\n')


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
    residue = []
    try:
        residue = residue_files(root)
    except (RuntimeError, OSError, ValueError) as error:
        limits.append('residue file coverage unknown (%s)' % error)
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
    left = []
    if residue:
        more = ' (+%d more)' % (len(residue) - 5) if len(residue) > 5 else ''
        left.append('%d backup/temporary file(s) left in the tree: %s%s; check origin and authorization first: remove only what this task created,'
                    ' allow-list a kept file under residue_allow in .dockit-config.yml, report the rest to its owner'
                    % (len(residue), ', '.join(map(shown, residue[:5])), more))
    if new:
        emit('; '.join(['%d closed workspace(s) not retired: %s; %s' % (len(new), ', '.join(new), hint)] + left + limits)); return 1
    notes = []
    if candidates or legacy:
        notes.append('%d merged worktree/branch candidate(s) and %d legacy closed workspace(s) to retire; %s' % (len(candidates), legacy, hint))
    notes += left
    if self_closed:
        notes.append('this closed task checkout must be retired from the primary after the session ends')
    if notes or limits:
        emit('; '.join(notes + limits)); return 3
    emit('No workspaces, branches or backup/temporary files left behind'); return 0


if __name__ == '__main__':
    sys.exit(main())
