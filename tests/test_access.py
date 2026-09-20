#!/usr/bin/env python3
"""Exercise real shell functions against disposable keys/directories."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'SD Card/ports_scripts/g02-access/common.sh'

class AccessTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.auth = self.root / 'ssh'
        self.auth.mkdir()
        self.keys = []
        for n in range(2):
            key = self.root / f'key{n}'
            subprocess.run(['ssh-keygen','-q','-t','ed25519','-N','','-f',str(key)],check=True)
            self.keys.append(Path(str(key)+'.pub'))
        self.original = '# Keep this comment\n' + self.keys[1].read_text()
        (self.auth/'authorized_keys').write_text(self.original)

    def call(self, action, key=None, success=True):
        args = ['sh','-c','. "$1"; "$2" "$3" "$4" || exit $?','test',str(LIB),action,str(self.auth),str(key or self.keys[0])]
        result = subprocess.run(args,text=True,capture_output=True)
        self.assertEqual(result.returncode == 0, success, result.stdout+result.stderr)
        return result.stdout

    def test_install_repeat_remove_preserves_others(self):
        self.call('install_key')
        auth = self.auth/'authorized_keys'
        installed = auth.read_text()
        self.assertIn(self.original, installed)
        self.assertIn(self.keys[0].read_text().split()[1], installed)
        self.assertEqual(auth.stat().st_mode & 0o777, 0o600)
        self.call('install_key')
        self.assertEqual(auth.read_text(), installed)
        self.call('remove_key')
        self.assertNotIn(self.keys[0].read_text().split()[1], auth.read_text())
        self.assertIn(self.original, auth.read_text())
        self.assertFalse((self.auth/'g02-access-managed.pub').exists())
        self.call('remove_key')

    def test_bad_and_private_keys_leave_auth_unchanged(self):
        bad = self.root/'bad.pub'
        for value in ['', 'ssh-ed25519 definitelynotavalidkey\n', self.keys[0].read_text()*2,
                      (self.root/'key0').read_text(), 'command="bad" '+self.keys[0].read_text()]:
            bad.write_text(value)
            self.call('install_key',bad,success=False)
            self.assertEqual((self.auth/'authorized_keys').read_text(),self.original)
            self.assertFalse((self.auth/'g02-access-managed.pub').exists())

    def test_preexisting_key_not_claimed_or_removed(self):
        self.call('install_key',self.keys[1])
        self.assertFalse((self.auth/'g02-access-managed.pub').exists())
        self.call('remove_key')
        self.assertEqual((self.auth/'authorized_keys').read_text(),self.original)

    def test_different_managed_key_rejected(self):
        self.call('install_key')
        before = (self.auth/'authorized_keys').read_bytes()
        self.call('install_key',self.keys[1],success=False)
        self.assertEqual((self.auth/'authorized_keys').read_bytes(),before)

    def test_symlink_rejected(self):
        auth = self.auth/'authorized_keys'
        auth.unlink()
        target = self.root/'outside'
        target.write_text('untouched')
        auth.symlink_to(target)
        self.call('install_key',success=False)
        self.assertEqual(target.read_text(),'untouched')

    def test_missing_authorized_keys(self):
        (self.auth/'authorized_keys').unlink()
        self.call('install_key')
        self.call('remove_key')
        self.assertEqual((self.auth/'authorized_keys').read_text().strip(),'')

    def test_crlf_public_key(self):
        key = self.root/'windows.pub'
        key.write_bytes(self.keys[0].read_bytes().replace(b'\n',b'\r\n'))
        self.call('install_key',key)

    def test_shell_syntax(self):
        for file in ROOT.glob('SD Card/**/*.sh'):
            subprocess.run(['sh','-n',str(file)],check=True)
            self.assertNotIn(b'\r',file.read_bytes())

if __name__ == '__main__':
    unittest.main(verbosity=2)
