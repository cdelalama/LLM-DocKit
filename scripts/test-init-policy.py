"""Verify a host rejection prevents all scaffold writes."""
import os
import json
import hashlib
import shutil
from pathlib import Path
import subprocess
import tempfile
import unittest

INIT = Path(__file__).with_name('dockit-init-project.sh')


class InitPolicyTests(unittest.TestCase):
    def test_new_project_has_only_child_idea_identity(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); source = root / 'source'; target = root / 'new-project'
            subprocess.run(['git', 'clone', '--quiet', '--no-hardlinks', str(INIT.parent.parent), str(source)], check=True)
            for name in ['dockit-init-project.sh', 'dockit-ideas.py']:
                shutil.copyfile(INIT.with_name(name), source / 'scripts' / name)
            subprocess.run(['git', '-C', str(source), 'add', 'scripts'], check=True)
            subprocess.run(['git', '-C', str(source), '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid', 'commit', '-qm', 'candidate init'], check=True)
            result = subprocess.run(['sh', str(INIT), 'new-project', '--source', str(source), '--target-dir', str(target)], env=dict(os.environ, XDG_CONFIG_HOME=str(root/'no-host-policy')), capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            data = json.loads((target/'docs/llm/IDEA_INDEX.json').read_text())
            self.assertEqual(data['project'], 'new-project')
            for name in ['entries', 'batches', 'registers', 'task_reconciliations']: self.assertEqual(data[name], [])
            self.assertFalse(list((target/'docs/llm/work').glob('*.json')))
            self.assertNotIn('LLM-DocKit', (target/'docs/llm/WORK_INDEX.md').read_text())
            self.assertFalse((target/'docs/TEMPLATE_IMPORT_REPAIR.md').exists())
            self.assertTrue((target/'LLM_START_HERE.md').read_text().startswith('<!-- doc-version: 0.1.0 -->\n# LLM Start Guide'))
            self.assertEqual((target/'docs/llm/REVIEWS.md').read_text(), '# Reviews\n\nNo project reviews have been recorded yet.\n')
            self.assertEqual(data['validator_sha256'], hashlib.sha256((target/'scripts/dockit-ideas.py').read_bytes()).hexdigest())
            revision = subprocess.check_output(['git','-C',str(target),'rev-parse','HEAD'], text=True).strip()
            checked = subprocess.run(['python3',str(target/'scripts/dockit-ideas.py'),'--project',str(target),'--baseline',revision],capture_output=True,text=True)
            self.assertEqual(checked.returncode,0,checked.stdout+checked.stderr)

    def test_linked_worktree_and_nested_copy(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp); source=root/'source'; linked=root/'linked'; target=root/'child'
            subprocess.run(['git','clone','--quiet','--no-hardlinks',str(INIT.parent.parent),str(source)],check=True)
            for name in ['dockit-init-project.sh','dockit-ideas.py']:
                shutil.copyfile(INIT.with_name(name),source/'scripts'/name)
            subprocess.run(['git','-C',str(source),'add','scripts'],check=True)
            subprocess.run(['git','-C',str(source),'-c','user.name=Fixture','-c','user.email=fixture@example.invalid','commit','-qm','candidate'],check=True)
            subprocess.run(['git','-C',str(source),'worktree','add','--quiet','--detach',str(linked)],check=True)
            env=dict(os.environ,XDG_CONFIG_HOME=str(root/'no-host-policy'))
            result=subprocess.run(['sh',str(INIT),'child','--source',str(linked),'--target-dir',str(target)],env=env,capture_output=True,text=True)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            nested=source/'nested';nested.mkdir()
            for name in ['VERSION','LLM_START_HERE.md']:shutil.copyfile(source/name,nested/name)
            result=subprocess.run(['sh',str(INIT),'bad','--source',str(nested),'--target-dir',str(root/'bad')],env=env,capture_output=True,text=True)
            self.assertNotEqual(result.returncode,0)
            self.assertFalse((root/'bad'/'.git').exists())

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
