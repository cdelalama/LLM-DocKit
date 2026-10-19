"""Registered template-import migration regression tests; no production writes."""
import copy
import hashlib
import importlib.util
import json
import pathlib
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = pathlib.Path(__file__).with_name('dockit-ideas.py')
spec = importlib.util.spec_from_file_location('ideas_repair', SCRIPT)
ideas = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ideas)

class ProductionRegistry(unittest.TestCase):
    def test_exact_reviewed_registry(self):
        self.assertEqual(set(ideas.TEMPLATE_IMPORTS), {'2f4ba1c91cc2ac0dd49682089bdf0916b6988138'})
        self.assertEqual(hashlib.sha256(json.dumps(ideas.TEMPLATE_IMPORTS,sort_keys=True).encode()).hexdigest(), '9897c0f8696a5e210ff4bcb5407c9b7fe0de308b37f70e2cc010dc8a55caa092')

class Repair(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='template-repair-')
        self.root = pathlib.Path(self.temp.name)
        self.git('init', '-q'); self.git('config','user.name','Fixture'); self.git('config','user.email','fixture@example.invalid')
        self.data = dict(schema=1,project='LLM-DocKit',validator_sha256=hashlib.sha256(SCRIPT.read_bytes()).hexdigest(),registers=[dict(path='docs/llm/DECISIONS.md',pattern=r'^## (D-\d+)')],batches=[],entries=[],task_reconciliations=[])
        self.write(ideas.INDEX, json.dumps(self.data)+'\n')
        self.write('docs/llm/work/import.json','{"state":"closed"}\n')
        self.write('docs/llm/WORK_INDEX.md','# Foreign owner\n')
        self.write('keep.txt','Retain\n')
        self.write('docs/llm/DECISIONS.md','## D-001 - Real admission decision\n')
        self.commit('foreign scaffold')
        self.birth = self.git('rev-parse','HEAD').strip()
        paths = [ideas.INDEX,'docs/llm/work/import.json','docs/llm/WORK_INDEX.md']
        self.files = {p:hashlib.sha256((self.root/p).read_bytes()).hexdigest() for p in paths}
        contract=dict(project=dict(name='fixture'),origin=dict(created_by='ForgeOS',workflow='/new-homelab-project'),birth=dict(retrofit=False))
        self.write('.forgeos/project-birth.json',json.dumps(contract)+'\n'); self.commit('admit new project')
        self.base=self.git('rev-parse','HEAD').strip()
        self.spec=dict(project='fixture',admission=self.base,contract_sha256=hashlib.sha256((self.root/'.forgeos/project-birth.json').read_bytes()).hexdigest(),template_revision='a'*40,files=self.files)
        self.registry=patch.dict(ideas.TEMPLATE_IMPORTS,{self.birth:self.spec},clear=True);self.registry.start()
        self.receipt=dict(schema=1,root=self.birth,admission=self.base,project='fixture',template_revision='a'*40,policy_revision='b'*40,review_manifest_sha256='c'*64,files=self.files)
        for p in paths: self.write(ideas.ARCHIVE+p,(self.root/p).read_text())
        (self.root/'docs/llm/work/import.json').unlink()
        self.write('docs/llm/WORK_INDEX.md','# Child work\n')
        self.data['project']='fixture';self.save()
    def tearDown(self):self.registry.stop();self.temp.cleanup()
    def git(self,*args):return subprocess.check_output(['git','-C',str(self.root),*args],text=True,stderr=subprocess.DEVNULL)
    def write(self,p,t):q=self.root/p;q.parent.mkdir(parents=True,exist_ok=True);q.write_text(t)
    def commit(self,m):self.git('add','.');self.git('commit','-qm',m)
    def save(self):self.write(ideas.INDEX,json.dumps(self.data)+'\n');self.write(ideas.REPAIR,json.dumps(self.receipt)+'\n')
    def check(self,baseline=None):return ideas.Checker(self.root,baseline or self.base).run()
    def fails(self,word):
        with self.assertRaisesRegex(ideas.Invalid,word):self.check()
    def test_candidate_committed_and_later_baselines(self):
        self.assertEqual(self.check()['status'],'pass');self.commit('repair');repair=self.git('rev-parse','HEAD').strip()
        self.assertEqual(self.check()['template_repair'],repair)
        self.write('new.txt','later');self.commit('later')
        self.assertEqual(self.check(repair)['status'],'pass')
    def test_multiple_roots(self):
        # Introduce another committed root without changing the working tree.
        tree=self.git('mktree').strip()
        other=subprocess.check_output(['git','-C',str(self.root),'commit-tree',tree,'-m','other root'],text=True).strip()
        merged=subprocess.check_output(['git','-C',str(self.root),'commit-tree',self.git('rev-parse','HEAD^{tree}').strip(),'-p',self.base,'-p',other,'-m','merge roots'],text=True).strip()
        self.git('update-ref','HEAD',merged);self.fails('single registered root')
    def test_second_transition(self):
        self.commit('repair');(self.root/ideas.REPAIR).unlink();self.commit('remove receipt');self.save();self.commit('re-add receipt');self.fails('Multiple repair transitions')
    def test_adopted_birth_cannot_be_registered_as_new(self):
        # Rebuild only the synthetic admission commit with a retrofit contract.
        contract=json.loads(self.git('show',self.base+':.forgeos/project-birth.json'))
        contract['birth']['retrofit']=True
        self.write('.forgeos/project-birth.json',json.dumps(contract)+'\n')
        self.git('add','.forgeos/project-birth.json');self.git('commit','--amend','-qm','adopted fixture')
        self.base=self.git('rev-parse','HEAD').strip();self.spec['admission']=self.base
        self.spec['contract_sha256']=hashlib.sha256((self.root/'.forgeos/project-birth.json').read_bytes()).hexdigest()
        self.receipt['admission']=self.base;self.save();self.fails('new creation')
    def test_modified_frozen_archive_after_commit(self):
        self.commit('repair');self.write(ideas.ARCHIVE+ideas.INDEX,'{}');self.commit('alter archive');self.fails('Frozen archive')

    def test_admission_register_deletion(self):
        self.write('docs/llm/DECISIONS.md','removed\n');self.fails('Admission register IDs disappeared')

    def test_unknown_root(self):
        ideas.TEMPLATE_IMPORTS.clear();self.fails('Unregistered')
    def test_receipt_mismatch(self):
        self.receipt['project']='wrong';self.save();self.fails('project')
    def test_modified_archive_and_extra_file(self):
        p=ideas.ARCHIVE+ideas.INDEX;self.write(p,'{}');self.fails('Frozen archive')
    def test_extra_archive_file(self):
        self.write(ideas.ARCHIVE+'extra.txt','x');self.fails('Archive set')
    def test_extra_deletion(self):
        (self.root/'keep.txt').unlink();self.fails('outside')
    def test_registered_contract_hash_mismatch(self):
        self.spec['contract_sha256']='0'*64;self.fails('contract differs')
    def test_current_identity_or_adoption(self):
        for field in ['identity','adoption']:
            j=json.loads((self.root/'.forgeos/project-birth.json').read_text())
            if field=='identity':j['project']['name']='wrong'
            else:j['project']['name']='fixture';j['birth']['retrofit']=True
            self.write('.forgeos/project-birth.json',json.dumps(j));self.fails('identity changed')
    def test_non_root_receipt(self):
        self.receipt['root']=self.base;self.save();self.fails('single registered root')
    def test_template_self_repair(self):
        self.data['project']='LLM-DocKit';self.spec['project']='LLM-DocKit';self.receipt['project']='LLM-DocKit';self.save();self.fails('project')
    def test_earlier_edit_fails(self):
        # A separate commit before repair cannot be retrospectively waived.
        self.write('unrelated.txt','committed before migration');self.git('add','unrelated.txt');self.git('commit','-qm','earlier edit');self.fails('first change')
    def test_receipt_deletion_after_commit(self):
        self.commit('repair');(self.root/ideas.REPAIR).unlink();self.fails('receipt disappeared')
        self.git('add','-u');self.git('commit','-qm','delete receipt');self.fails('receipt disappeared')
    def test_frozen_receipt(self):
        self.commit('repair');self.receipt['review_manifest_sha256']='d'*64;self.save();self.fails('Frozen repair receipt')
    def test_foreign_record_cannot_remain_live(self):
        self.write('docs/llm/work/import.json','{"state":"closed"}\n');self.fails('remains live')
    def test_later_child_deletion_still_fails(self):
        self.data['registers']=[dict(path='docs/decisions.md',pattern=r'^## (D-\d+)')]
        self.write('docs/decisions.md','## D-001\n');self.save();self.commit('repair')
        self.write('docs/decisions.md','empty\n');self.fails('IDs disappeared')
    def test_archive_byte_identity_includes_line_endings(self):
        (self.root/(ideas.ARCHIVE+'docs/llm/WORK_INDEX.md')).write_bytes(b'# Foreign owner\r\n');self.fails('Frozen archive')

if __name__=='__main__':unittest.main()
