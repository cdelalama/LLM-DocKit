#!/usr/bin/env python3
"""Behavioral omission, provenance and closeout regressions in isolated Git repos."""
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('dockit-ideas.py')
spec = importlib.util.spec_from_file_location('ideas', SCRIPT)
ideas = importlib.util.module_from_spec(spec); spec.loader.exec_module(ideas)


class Continuity(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='idea-test-')
        self.root = Path(self.tmp.name)
        self.git('init', '-q'); self.git('config', 'user.name', 'Fixture'); self.git('config', 'user.email', 'fixture@example.invalid')
        self.write('docs/llm/DECISIONS.md', '## D-001 - First\n\n## D-002 - Second\n')
        self.write('docs/source.md', '# Original suggestion\nUnrecorded extra idea\n')
        self.write('src/app.py', 'implemented = True\n')
        self.write('docs/llm/work/capture.json', json.dumps({'state': 'active'}))
        self.git('add', '.'); self.git('commit', '-qm', 'source')
        source = self.git('rev-parse', 'HEAD').strip()
        origin = {'path': 'docs/source.md', 'revision': source, 'contains': 'Original suggestion'}
        self.data = {'schema': 1, 'project': 'fixture', 'validator_sha256': hashlib.sha256(SCRIPT.read_bytes()).hexdigest(),
                     'registers': [{'path': 'docs/llm/DECISIONS.md', 'pattern': r'^## (D-\d{3})\b'}],
                     'batches': [{'id': 'B001', 'date': '2026-10-07', 'sources': [origin], 'excluded': ['Other conversations'], 'unknown': ['Other hosts'], 'coverage_claim': 'declared_corpus_only', 'remaining_backfill': 'Other sources pending', 'cursor': 'Next archive'}],
                     'entries': [{'id': 'IDEA-0001', 'record': 'native', 'kind': 'agent_suggestion', 'title': 'Example', 'owner': 'fixture', 'origin': {'date': '2026-10-07', 'attribution': 'Fixture suggestion', 'sources': [origin]}, 'batch': 'B001', 'state': 'deferred', 'recall_trigger': 'When interface work resumes', 'documentation_refs': [origin]}],
                     'task_reconciliations': []}
        self.save(); self.git('add', '.'); self.git('commit', '-qm', 'adopt')
        self.base = self.git('rev-parse', 'HEAD').strip()

    def tearDown(self):
        self.tmp.cleanup()

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.root), *args], text=True, stderr=subprocess.DEVNULL)

    def write(self, path, text):
        p = self.root / path; p.parent.mkdir(parents=True, exist_ok=True); p.write_text(text)

    def save(self):
        self.write(ideas.INDEX, json.dumps(self.data))

    def check(self, baseline=True):
        self.save()
        return ideas.Checker(self.root, self.base if baseline else None).run()

    def fails(self, word):
        with self.assertRaisesRegex(ideas.Invalid, word): self.check()

    def test_valid_and_explicit_baseline(self):
        result = self.check(); self.assertEqual(result['status'], 'pass'); self.assertEqual(result['baseline_mode'], 'explicit')

    def test_delete_index_working_and_committed(self):
        (self.root / ideas.INDEX).unlink()
        with self.assertRaisesRegex(ideas.Invalid, 'deleted'): ideas.Checker(self.root, self.base).run()
        self.git('add', '-u'); self.git('commit', '-qm', 'delete')
        with self.assertRaisesRegex(ideas.Invalid, 'deleted'): ideas.Checker(self.root).run()
        self.write('unrelated.txt', 'dirty after committed deletion')
        with self.assertRaisesRegex(ideas.Invalid, 'deleted'): ideas.Checker(self.root).run()

    def test_deletion_rename_kind_and_origin(self):
        original = copy.deepcopy(self.data)
        for field in ['delete', 'id', 'kind', 'origin']:
            with self.subTest(field=field):
                self.data = copy.deepcopy(original)
                if field == 'delete': self.data['entries'] = []
                elif field == 'origin': self.data['entries'][0]['origin']['attribution'] = 'Invented operator request'
                elif field == 'kind': self.data['entries'][0]['kind'] = 'operator_request'
                else: self.data['entries'][0]['id'] = 'IDEA-9999'
                self.fails('disappeared|immutable|origin')

    def test_delete_register_id_and_pattern_escape(self):
        self.write('docs/llm/DECISIONS.md', '## D-001 - First\n'); self.fails('IDs disappeared')
        self.data['registers'][0]['pattern'] = r'^## (D-001)\b'; self.fails('pattern changed')
        self.data['registers'] = []; self.fails('declaration disappeared')

    def test_register_move_preserves_every_id(self):
        (self.root/'docs/llm/DECISIONS.md').rename(self.root/'docs/llm/ARCHIVED_DECISIONS.md')
        self.data['registers'][0]['moved_to'] = 'docs/llm/ARCHIVED_DECISIONS.md'
        self.assertEqual(self.check()['status'], 'pass')

    def test_state_dispositions(self):
        original = copy.deepcopy(self.data)
        for state in ['accepted','in_progress','rejected','superseded','transferred','implemented']:
            with self.subTest(state=state):
                self.data=copy.deepcopy(original); self.data['entries'][0]['state']=state
                self.fails('required|Reference must')
        self.data=copy.deepcopy(original); self.data['entries'][0]['recall_trigger']=''; self.fails('recall')

    def test_documentation_is_not_implementation(self):
        e=self.data['entries'][0]; e.update(state='implemented',authority='Source observation',rationale='Present in published implementation',evidence=e['documentation_refs'],acceptance={'state':'pending','reason':'Runtime not observed'})
        self.fails('documentation alone')
        e['evidence']=[{'path':'src/app.py','revision':self.base}]
        self.assertEqual(self.check()['status'],'pass')

    def test_reference_has_no_lifecycle(self):
        e=self.data['entries'][0]; e.update(record='reference',ref=e['documentation_refs'][0])
        self.fails('reference entries cannot own')

    def test_historical_reference_does_not_hide_missing_live_authority(self):
        e=self.data['entries'][0]
        e.update(record='reference',ref=e['documentation_refs'][0])
        del e['state'];del e['documentation_refs']
        # No prior native entry in the comparison: this is an adoption fixture.
        self.save();self.git('add','.');self.git('commit','-qm','reference adoption');self.base=self.git('rev-parse','HEAD').strip()
        self.assertEqual(self.check()['status'],'pass')
        self.write('docs/source.md','# Changed content without original anchor\n');self.fails('Missing anchor')
        (self.root/'docs/source.md').unlink();self.fails('Missing file')

    def test_closed_task_reconciles_idea_but_does_not_implement_it(self):
        self.write('docs/llm/work/capture.json',json.dumps({'state':'closed'})); self.fails('lacks idea reconciliation')
        self.data['task_reconciliations']=[{'task':'docs/llm/work/capture.json','ideas':['IDEA-0001'],'no_ideas_reason':''}]
        self.assertEqual(self.check()['status'],'pass'); self.assertEqual(self.data['entries'][0]['state'],'deferred')

    def test_created_closed_and_deleted_tasks(self):
        self.write('docs/llm/work/new.json',json.dumps({'state':'closed'})); self.fails('lacks idea reconciliation')
        (self.root/'docs/llm/work/new.json').unlink(); (self.root/'docs/llm/work/capture.json').unlink(); self.fails('Task record disappeared')

    def test_unknown_coverage_pin_and_path_failures(self):
        original=copy.deepcopy(self.data)
        self.data['batches'][0]['coverage_claim']='complete'; self.fails('bounded')
        self.data=copy.deepcopy(original); self.data['validator_sha256']='0'*64; self.fails('adopted hash')
        self.data=copy.deepcopy(original); self.data['entries'][0]['documentation_refs']=[{'path':'../outside'}]; self.fails('Unsafe')

    def test_inferred_baseline_never_publication_pass(self):
        self.assertEqual(self.check(False)['status'],'warning')
        with self.assertRaises(ideas.Invalid):ideas.Checker(self.root,'not-a-real-ref')

    def test_unresolved_cross_project_is_visible(self):
        self.data['entries'][0]['documentation_refs']=[{'path':'docs/file.md','project':'other'}]
        result=self.check(); self.assertEqual(result['status'],'warning'); self.assertIn('Unresolved',result['warnings'][0])

    def test_semantic_omission_is_outside_mechanical_proof(self):
        # Source deliberately includes a second idea absent from the index.
        # A reviewer must flag it; the structural checker cannot discover it.
        self.assertEqual(self.check()['status'],'pass')
        self.assertIn('Unrecorded extra idea',(self.root/'docs/source.md').read_text())

    def test_session_entrypoint_detects_whole_index_deletion(self):
        scripts=self.root/'scripts';scripts.mkdir()
        shutil.copy2(SCRIPT,scripts/SCRIPT.name)
        shutil.copy2(SCRIPT.with_name('dockit-validate-session.sh'),scripts/'dockit-validate-session.sh')
        (self.root/ideas.INDEX).unlink()
        result=subprocess.run(['sh',str(scripts/'dockit-validate-session.sh'),'--project',str(self.root),'--check','idea-continuity'],capture_output=True,text=True)
        self.assertEqual(result.returncode,1,result.stdout+result.stderr)


if __name__=='__main__':unittest.main()
