"""Verify a host rejection prevents all scaffold writes."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

INIT = Path(__file__).with_name('dockit-init-project.sh')


class InitPolicyTests(unittest.TestCase):
    def test_session_start_reports_existing_adoption_failure_without_running_project_code(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); project = root / 'project'; project.mkdir()
            (project / 'LLM_START_HERE.md').write_text('# Start\nRead docs/PROJECT_CONTEXT.md.\n')
            config = root / 'config'; policy = config / 'llm-dockit/init-policy'
            policy.parent.mkdir(parents=True)
            policy.write_text('#!/bin/sh\n[ "$1" = "--check-existing" ] || exit 99\necho "Missing owner adoption"\nexit 3\n')
            policy.chmod(0o700)
            result = subprocess.run(['sh', str(INIT.with_name('dockit-bootstrap-context.sh')),
                                     '--project', str(project), '--human'],
                                    env=dict(os.environ, XDG_CONFIG_HOME=str(config)), capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('Host intake diagnosis (exit 3): Missing owner adoption', result.stdout)

    def test_rejection_and_broken_hook_leave_target_absent(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); config = root / 'config'; policy = config / 'llm-dockit/init-policy'
            policy.parent.mkdir(parents=True)
            target = root / 'must-not-exist'
            env = dict(os.environ, XDG_CONFIG_HOME=str(config))
            for kind in ['reject', 'broken', 'non_executable']:
                with self.subTest(kind=kind):
                    if policy.exists() or policy.is_symlink(): policy.unlink()
                    if kind == 'broken': policy.symlink_to(root / 'missing')
                    else:
                        policy.write_text('#!/bin/sh\nexit 77\n'); policy.chmod(0o700 if kind == 'reject' else 0o600)
                    result = subprocess.run(['sh', str(INIT), 'example', '--target-dir', str(target)], env=env, capture_output=True, text=True)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertFalse(target.exists())
                    self.assertIn('policy', result.stderr)


if __name__ == '__main__':
    unittest.main()
