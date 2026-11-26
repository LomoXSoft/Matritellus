"""Builds the Android package: dist/Matritellus.apk, signed with the game's own key.

    python tools/make_apk.py X.Y.Z      (the version being released, e.g. 0.0.4)
    python tools/make_apk.py            (a test build: the version already in project.godot, or the last git tag)

0. the version: X.Y.Z goes into godot/project.godot (application/config/version, where the game can read it) and into
   the Android preset, as the name the phone shows (version/name) and as the number that tells it which build is
   newer (version/code = X*10000 + Y*100 + Z, so 0.0.4 is 4 and 0.1.0 is 100: it must only ever go up);
1. Godot exports the "Android" preset (godot/export_presets.cfg), signed with the release keystore in
   C:/Users/luis_/Fable/tools/android (its password is in keystore_pass.txt there, and is never printed);
2. the radio stations (godot/radio, which Godot leaves out: the folder has a .gdignore) go into the package as
   assets/radio/..., together with a radio/index.json manifest, and every injected file is registered in
   assets/assets.sparsepck (Godot 4.7's sparse bundle PCK index) so res://radio works natively on Android;
3. the package is aligned and signed again, and the signature and radio index are checked.
"""
import hashlib, json, os, pathlib, re, struct, subprocess, sys, zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
AND = pathlib.Path('C:/Users/luis_/Fable/tools/android')
GODOT = 'C:/Users/luis_/Fable/tools/godot/Godot_v4.7.2-stable_win64_console.exe'
BT = AND / 'sdk' / 'build-tools' / '37.0.0'
OUT = ROOT / 'dist' / 'Matritellus.apk'
env = dict(os.environ)
env['JAVA_HOME'] = str(AND / 'jdk-17.0.21+9')
env['GODOT_ANDROID_KEYSTORE_RELEASE_PATH'] = str(AND / 'matritellus-release.keystore')
env['GODOT_ANDROID_KEYSTORE_RELEASE_USER'] = 'matritellus'
env['GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD'] = (AND / 'keystore_pass.txt').read_text().strip()

PROJECT = ROOT / 'godot' / 'project.godot'
PRESETS = ROOT / 'godot' / 'export_presets.cfg'


def _version() -> str:
    if len(sys.argv) > 1:
        return sys.argv[1].lstrip('v')
    m = re.search(r'^config/version="([^"]+)"', PROJECT.read_text(encoding='utf8'), re.M)
    if m:
        return m.group(1)
    tag = subprocess.run(['git', 'describe', '--tags', '--abbrev=0'], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    return tag.lstrip('v') or '0.0.0'


VERSION = _version()
if not re.fullmatch(r'\d+\.\d+\.\d+', VERSION):
    sys.exit('the version must be X.Y.Z, not %r' % VERSION)
x, y, z = (int(n) for n in VERSION.split('.'))
CODE = max(1, x * 10000 + y * 100 + z)

text = PROJECT.read_text(encoding='utf8')            # the project: application/config/version
if re.search(r'^config/version=', text, re.M):
    new = re.sub(r'^config/version=.*$', 'config/version="%s"' % VERSION, text, flags=re.M)
else:
    new = text.replace('config/name="Matritellus"\n', 'config/name="Matritellus"\nconfig/version="%s"\n' % VERSION, 1)
    assert new != text, 'no config/name line in project.godot'
if new != text:
    PROJECT.write_text(new, encoding='utf8', newline='\n')

text = PRESETS.read_text(encoding='utf8')            # the Android preset only (the others have no version/code)
head, sep, rest = text.partition('name="Android"')
assert sep, 'no Android preset'
rest = re.sub(r'^version/code=.*$', 'version/code=%d' % CODE, rest, count=1, flags=re.M)
rest = re.sub(r'^version/name=.*$', 'version/name="%s"' % VERSION, rest, count=1, flags=re.M)
if head + sep + rest != text:
    PRESETS.write_text(head + sep + rest, encoding='utf8', newline='\n')

OUT.parent.mkdir(exist_ok=True)
r = subprocess.run([GODOT, '--headless', '--path', str(ROOT / 'godot'), '--export-release', 'Android', str(OUT)], env=env, capture_output=True, text=True, encoding='utf8', errors='replace')
if r.returncode != 0 or not OUT.exists():
    print(r.stdout[-3000:], r.stderr[-3000:]); sys.exit('export failed')

def _patch_sparsepck(data: bytes, extra: list) -> bytes:
    """Append sparse bundle entries (rel_path, content_bytes) to Godot 4's assets/assets.sparsepck index."""
    assert data[:4] == b'GDPC', 'unexpected sparsepck header'
    ver, _, _, _, flags = struct.unpack_from('<5I', data, 4)
    assert ver >= 3 and (flags & 0x4), 'unexpected sparsepck version/flags: v%d flags=0x%x' % (ver, flags)
    dir_off = struct.unpack_from('<Q', data, 32)[0]
    fcount = struct.unpack_from('<I', data, dir_off)[0]
    existing = set()
    off = dir_off + 4
    for _ in range(fcount):
        plen = struct.unpack_from('<I', data, off)[0]
        off += 4
        existing.add(data[off:off + plen].rstrip(b'\x00').decode('utf8', 'replace'))
        off += plen + 36
    assert off == len(data), 'sparsepck trailing bytes: %d' % (len(data) - off)
    out = bytearray(data)
    added = 0
    for rel, content in extra:
        if rel in existing:
            continue
        raw = rel.encode('utf8')
        padded = raw + b'\x00' * ((-len(raw)) % 4)
        out += struct.pack('<I', len(padded)) + padded
        out += struct.pack('<QQ', 0, len(content))
        out += hashlib.md5(content).digest()
        out += struct.pack('<I', 0)
        added += 1
    struct.pack_into('<I', out, dir_off, fcount + added)
    return bytes(out)


def _radio_manifest(radio: pathlib.Path) -> bytes:
    """Manifest of radio1..N and their sorted tracks so Android needs no DirAccess scan of the APK."""
    stations = []
    n = 1
    while (radio / ('radio%d' % n)).is_dir():
        d = radio / ('radio%d' % n)
        files = sorted(p.name for p in d.iterdir() if p.is_file() and p.suffix.lower() in ('.ogg', '.mp3', '.wav'))
        stations.append({'dir': 'radio%d' % n, 'files': files})
        n += 1
    return json.dumps({'stations': stations}, ensure_ascii=False, indent=2).encode('utf8')


tmp = OUT.with_name('_radio.apk')
radio = ROOT / 'godot' / 'radio'
radio_entries = []
for p in sorted(radio.rglob('*')):
    rel = p.relative_to(radio).as_posix()
    if p.is_file() and not rel.startswith('_reserva') and p.name not in ('.gdignore', 'LEEME.txt'):
        radio_entries.append(('radio/' + rel, p.read_bytes(), zipfile.ZIP_STORED if p.suffix.lower() in ('.ogg', '.mp3', '.png') else zipfile.ZIP_DEFLATED))
manifest_bytes = _radio_manifest(radio)
radio_entries.append(('radio/index.json', manifest_bytes, zipfile.ZIP_DEFLATED))

with zipfile.ZipFile(OUT) as zin, zipfile.ZipFile(tmp, 'w') as zout:
    sparse_found = False
    for it in zin.infolist():
        if it.filename.startswith('META-INF/'):
            continue
        raw = zin.read(it.filename)
        if it.filename == 'assets/assets.sparsepck':
            raw = _patch_sparsepck(raw, [(rel, content) for rel, content, _ in radio_entries])
            sparse_found = True
        zout.writestr(it, raw, compress_type=it.compress_type)
    assert sparse_found, 'assets/assets.sparsepck not found in exported APK'
    for rel, content, ctype in radio_entries:
        zout.writestr('assets/' + rel, content, compress_type=ctype)
n = len(radio_entries)
aligned = OUT.with_name('_aligned.apk')
subprocess.run([str(BT / 'zipalign.exe'), '-f', '-p', '4', str(tmp), str(aligned)], check=True)
signer = str(BT / 'apksigner.bat')
subprocess.run([signer, 'sign', '--ks', str(AND / 'matritellus-release.keystore'), '--ks-key-alias', 'matritellus',
                '--ks-pass', 'file:' + str(AND / 'keystore_pass.txt'), '--out', str(OUT), str(aligned)], env=env, check=True, shell=True)
subprocess.run([signer, 'verify', str(OUT)], env=env, check=True, shell=True)
# Verify every station and track from index.json is both in the APK and registered in assets.sparsepck
with zipfile.ZipFile(OUT) as zchk:
    names = set(zchk.namelist())
    sd = zchk.read('assets/assets.sparsepck')
    doff = struct.unpack_from('<Q', sd, 32)[0]
    fc = struct.unpack_from('<I', sd, doff)[0]
    indexed = set()
    pos = doff + 4
    for _ in range(fc):
        pl = struct.unpack_from('<I', sd, pos)[0]
        pos += 4
        indexed.add(sd[pos:pos + pl].rstrip(b'\x00').decode('utf8', 'replace'))
        pos += pl + 36
    assert pos == len(sd), 'corrupt sparsepck after patch'
    mf = json.loads(zchk.read('assets/radio/index.json').decode('utf8'))
    assert mf['stations'], 'no radio stations in index.json'
    assert 'radio/index.json' in indexed, 'radio/index.json missing from sparsepck'
    for st in mf['stations']:
        assert st['files'], 'empty station: ' + st['dir']
        for fn in st['files']:
            rel = 'radio/%s/%s' % (st['dir'], fn)
            assert ('assets/' + rel) in names and rel in indexed, 'missing radio track in APK/sparsepck: ' + rel
for f in (tmp, aligned, OUT.with_name(OUT.name + '.idsig')):
    if f.exists():
        f.unlink()
print('%s: version %s (code %d), %.0f MB, %d radio files (%d stations, sparsepck=%d), signed and verified' % (
    OUT, VERSION, CODE, OUT.stat().st_size / 2 ** 20, n, len(mf['stations']), fc))
