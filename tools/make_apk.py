"""Builds the Android package: dist/Matritellus.apk, signed with the game's own key.

    python tools/make_apk.py X.Y.Z      (the version being released, e.g. 0.0.4)
    python tools/make_apk.py            (a test build: the version already in project.godot, or the last git tag)

0. the version: X.Y.Z goes into godot/project.godot (application/config/version, where the game can read it) and into
   the Android preset, as the name the phone shows (version/name) and as the number that tells it which build is
   newer (version/code = X*10000 + Y*100 + Z, so 0.0.4 is 4 and 0.1.0 is 100: it must only ever go up);
1. Godot exports the "Android" preset (godot/export_presets.cfg), signed with the release keystore in
   C:/Users/luis_/Fable/tools/android (its password is in keystore_pass.txt there, and is never printed);
2. the radio stations (godot/radio, which Godot leaves out: the folder has a .gdignore) go into the package as
   assets/radio/..., where the game looks for them on a phone (ambience.gd radio_root);
3. the package is aligned and signed again, and the signature checked.
"""
import os, pathlib, re, subprocess, sys, zipfile

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

tmp = OUT.with_name('_radio.apk')
radio = ROOT / 'godot' / 'radio'
with zipfile.ZipFile(OUT) as zin, zipfile.ZipFile(tmp, 'w') as zout:
    for it in zin.infolist():
        if not it.filename.startswith('META-INF/'):
            zout.writestr(it, zin.read(it.filename), compress_type=it.compress_type)
    n = 0
    for p in sorted(radio.rglob('*')):
        rel = p.relative_to(radio).as_posix()
        if p.is_file() and not rel.startswith('_reserva') and p.name not in ('.gdignore', 'LEEME.txt'):
            zout.write(str(p), 'assets/radio/' + rel, compress_type=zipfile.ZIP_STORED if p.suffix in ('.ogg', '.mp3', '.png') else zipfile.ZIP_DEFLATED)
            n += 1
aligned = OUT.with_name('_aligned.apk')
subprocess.run([str(BT / 'zipalign.exe'), '-f', '-p', '4', str(tmp), str(aligned)], check=True)
signer = str(BT / 'apksigner.bat')
subprocess.run([signer, 'sign', '--ks', str(AND / 'matritellus-release.keystore'), '--ks-key-alias', 'matritellus',
                '--ks-pass', 'file:' + str(AND / 'keystore_pass.txt'), '--out', str(OUT), str(aligned)], env=env, check=True, shell=True)
subprocess.run([signer, 'verify', str(OUT)], env=env, check=True, shell=True)
for f in (tmp, aligned, OUT.with_name(OUT.name + '.idsig')):
    if f.exists():
        f.unlink()
print('%s: version %s (code %d), %.0f MB, %d radio files, signed and verified' % (OUT, VERSION, CODE, OUT.stat().st_size / 2 ** 20, n))
