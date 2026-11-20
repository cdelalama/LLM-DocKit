import importlib.util
from datetime import datetime, timezone
import json
from pathlib import Path
import tempfile
import unittest

spec=importlib.util.spec_from_file_location('runtime',Path(__file__).with_name('dockit-runtime.py'))
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
NOW=datetime(2026,11,20,tzinfo=timezone.utc)
class Tests(unittest.TestCase):
    def base(self):return {'schema':1,'run_id':'test','project':'forgeos','task':'test','state':'none','reason':'Source-only fixture test; no Docker runtime created'}
    def test_absent_is_unknown(self):
        with tempfile.TemporaryDirectory() as tmp:
            issues,count=m.check(Path(tmp));self.assertTrue(issues);self.assertEqual(count,0)
    def test_none_requires_reason_and_cannot_hide_object(self):
        row=self.base();m.validate(row,'test',NOW)
        row['reason']=''
        with self.assertRaises(ValueError):m.validate(row,'test',NOW)
        row=self.base();row['object_id']='retained'
        with self.assertRaises(ValueError):m.validate(row,'test',NOW)
    def test_expired_and_unknown_hold_fail(self):
        row=self.base()|{'state':'held','host':'nas','object_id':'a'*64,'owner':'home-infra','lease_until':'2026-11-21T00:00:00Z','next_action':'Reconcile exact object'}
        m.validate(row,'test',NOW)
        row['lease_until']='2026-11-19T00:00:00Z'
        with self.assertRaises(ValueError):m.validate(row,'test',NOW)
        row.update(state='unknown',lease_until='2026-11-21T00:00:00Z')
        with self.assertRaises(ValueError):m.validate(row,'test',NOW)
    def test_retired_needs_readback_hash_and_nonfuture_observation(self):
        row=self.base()|{'state':'retired','host':'nas','object_id':'a'*64,'owner':'home-infra','evidence':{'reference':'private:run-test','sha256':'a'*64},'retirement':{'absent':True,'observed_at':'2026-11-19T00:00:00Z'}}
        m.validate(row,'test',NOW)
        for retired in [{'absent':False,'observed_at':'2026-11-19T00:00:00Z'},{'absent':True,'observed_at':'2027-11-19T00:00:00Z'}]:
            row['retirement']=retired
            with self.assertRaises(ValueError):m.validate(row,'test',NOW)
    def test_duplicate_keys_and_symlinks(self):
        with self.assertRaises(ValueError):json.loads('{"state":"none","state":"retired"}',object_pairs_hook=m.unique)
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);d=root/'docs/llm/runtime';d.mkdir(parents=True);f=root/'outside';f.write_text(json.dumps(self.base()));(d/'test.json').symlink_to(f)
            issues,count=m.check(root,NOW);self.assertTrue(issues);self.assertEqual(count,1)
    def test_malformed_receipt_is_failure_not_crash(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);d=root/'docs/llm/runtime';d.mkdir(parents=True);(d/'test.json').write_text('[]')
            self.assertTrue(m.check(root,NOW)[0])
if __name__=='__main__':unittest.main()
