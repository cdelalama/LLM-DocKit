#!/usr/bin/env python3
"""Schema tests use synthetic records; no host paths or private task evidence."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('records', Path(__file__).with_name('dockit-workspace.py'))
module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)


class Records(unittest.TestCase):
    def record(self):
        return dict(schema=1, id='task', project='sample', purpose='Fixture', state='retained', branch='work/task', artifacts=['docs/result.md'], next_step='Review result')

    def test_portable_record(self):
        self.assertEqual(module.validate(self.record())['project'], 'sample')

    def test_invalid_inputs(self):
        for field, value in [('id', '../task'), ('state', 'garbage'), ('schema', True), ('purpose', ''), ('artifacts', ['/tmp/private']), ('artifacts', ['../secret']), ('artifacts', ['C:\\secret']), ('branch', 'a\nb')]:
            with self.subTest(field=field, value=value):
                record = self.record(); record[field] = value
                with self.assertRaises(ValueError): module.validate(record)

    def test_linked_checkout_validation_does_not_write(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / 'repo'; task = Path(temp) / 'task'
            for args in [('init', '-q', str(root)), ('-C', str(root), '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '--allow-empty', '-qm', 'fixture'), ('-C', str(root), 'worktree', 'add', '-qb', 'task', str(task))]:
                subprocess.run([('/usr/bin/git' if sys.platform.startswith('linux') else 'git'), *args], check=True, capture_output=True)
            directory = task / 'docs/llm/work'; directory.mkdir(parents=True)
            path = directory / 'task.json'; path.write_text(json.dumps(self.record()))
            before = path.read_bytes(); self.assertEqual(len(module.records(task)), 1)
            self.assertEqual(before, path.read_bytes())


if __name__ == '__main__': unittest.main()
