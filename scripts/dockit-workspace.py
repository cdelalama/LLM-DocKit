#!/usr/bin/env python3
"""Validate portable parent-owned work records. Never move or delete a checkout."""
import argparse
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys

IDENTITY = re.compile(r'[A-Za-z0-9_][A-Za-z0-9._-]{0,119}\Z')
STATES = {'active', 'paused', 'pending-integration', 'retained', 'closed'}
FIELDS = {'schema', 'id', 'project', 'purpose', 'state', 'branch', 'artifacts', 'next_step'}


def require(ok, message):
    if not ok:
        raise ValueError(message)


def validate(record):
    require(type(record) is dict and set(record) == FIELDS, 'Unexpected work record fields')
    require(type(record['schema']) is int and record['schema'] == 1, 'Unsupported work record schema')
    for key in ('id', 'project'):
        require(type(record[key]) is str and IDENTITY.fullmatch(record[key]), 'Invalid ' + key)
    require(record['state'] in STATES, 'Invalid work disposition')
    for key in ('purpose', 'next_step'):
        require(type(record[key]) is str and 1 <= len(record[key]) <= 1000 and '\x00' not in record[key], 'Missing/invalid ' + key)
    require(type(record['branch']) is str and len(record['branch']) <= 240 and '\n' not in record['branch'], 'Invalid branch reference')
    require(type(record['artifacts']) is list and len(record['artifacts']) <= 100, 'Invalid artifact list')
    for value in record['artifacts']:
        require(type(value) is str and value and '\\' not in value and ':' not in value
                and not PurePosixPath(value).is_absolute() and '..' not in PurePosixPath(value).parts,
                'Artifact must be a portable repository-relative path')
    return record


def records(project):
    root = Path(project).resolve(strict=True)
    result = subprocess.run(['git', '-C', str(root), 'rev-parse', '--show-toplevel'], capture_output=True, text=True)
    require(result.returncode == 0 and Path(result.stdout.strip()).resolve() == root, 'Expected Git checkout root')
    directory = root / 'docs/llm/work'
    if not directory.exists():
        return []
    require(not any(p.is_symlink() for p in [directory, directory.parent, directory.parent.parent]), 'Symlinked work records refused')
    rows = []
    for path in sorted(directory.glob('*.json')):
        require(path.is_file() and not path.is_symlink(), 'Work record must be a regular file')
        row = validate(json.loads(path.read_text(encoding='utf-8')))
        require(path.stem == row['id'], 'Work record filename/ID mismatch')
        rows.append(row)
    require(len({r['project'] for r in rows}) <= 1, 'Mixed parent identities in one checkout')
    return rows


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--project', required=True)
    p.add_argument('--json', action='store_true')
    a = p.parse_args()
    rows = records(a.project)
    if a.json:
        print(json.dumps({'status': 'ok', 'records': rows}, sort_keys=True))
    else:
        print('Work records: %d valid; live paths remain host-local' % len(rows))


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, TypeError, KeyError) as error:
        print('Work record validation failed: ' + str(error), file=sys.stderr)
        sys.exit(2)
