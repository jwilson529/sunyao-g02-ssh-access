#!/usr/bin/env python3
"""Build a credentials-free release from an explicit allowlist."""
import hashlib
from pathlib import Path
import zipfile
ROOT = Path(__file__).resolve().parents[1]
VERSION = '1.0.1'
files = [ROOT/p for p in ['README.md','START HERE.html','LICENSE','Setup Windows.cmd','Connect Windows.cmd']]
for pattern in ['docs/*.md','assets/*.svg','tools/*.ps1','SD Card/**/*.sh']:
    files.extend(sorted(ROOT.glob(pattern)))
out = ROOT/'dist'
out.mkdir(exist_ok=True)
archive = out/f'sunyao-g02-ssh-access-v{VERSION}.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for path in files:
        data = path.read_bytes()
        assert b'PRIVATE KEY-----' not in data, path
        if path.suffix in ['.cmd','.ps1']:
            data = data.replace(b'\r\n',b'\n').replace(b'\n',b'\r\n')
        z.writestr(path.relative_to(ROOT).as_posix(),data)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert not any(n.endswith(('.pub','.key','.pem')) for n in z.namelist())
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
(out/'SHA256SUMS.txt').write_text(f'{digest}  {archive.name}\n')
print(f'{archive}\nSHA256 {digest}\n{len(files)} files; no keys included.')
