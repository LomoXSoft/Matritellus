r"""The project as the Android package is made from it: a copy of godot/ in dist/_android/godot whose 3D textures are
imported "VRAM compressed" (ETC2 on a phone) instead of lossless.

    python tools/android_copia.py          make or bring up to date the copy, and import it (make_apk.py calls it)

Why (Sistemas, 28 Nov 2026; the user: "Bajar la memoria de vídeo en el móvil [...] solo para android. Steam Machine
ejecuta el juego bastante bien"): every texture of the game is imported lossless, so a graphics card keeps it as it
is, four bytes a pixel. On the computer and the Steam Machine that is fine and stays so (the shared godot/ folder is
never touched here: the other sessions' tests would reimport under their feet). On a phone the game took some 2.6 GB
of video memory -- a phone's video memory is its RAM -- 1.2 GB of it textures. Compressed, the 3D ones take a quarter.

Which textures: the lossless ones that make mipmaps (mipmaps/generate=true), the textures of 3D things (the photo
textures of the houses, the arcade machines, the cars...). Lettering, graffiti, pixel art and the menus' pictures
(no mipmaps) stay lossless: compression smudges sharp edges. So do the small and the thin ones (under MIN_SIDE pixels on
their shorter side: the cars' colour strips of 1x32, 256x64...), where 4x4 blocks would bleed one colour into the next and
nothing is saved. The photo sets' normal.jpg are told they are normal maps (compress/normal_map=1: headless, nothing
finds it out by itself).

How: robocopy mirrors godot/ (without shots/, the self-test's pictures, nor .godot/, the copy keeps its own cache, the
first time copied from godot/.godot so that only the changed textures are imported again). data/ is not copied: it is
a junction to godot/data. Then the copy's .import files are rewritten and Godot imports the copy (--import).

To throw the copy away: first `cmd /c rmdir dist\_android\godot\data` (the junction alone), then the rest. A deleting
that follows the junction (PowerShell's Remove-Item -Recurse, some file managers) would empty godot/data itself.
"""
import os, pathlib, re, shutil, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'godot'
COPY = ROOT / 'dist' / '_android' / 'godot'
GODOT = 'C:/Users/luis_/Fable/tools/godot/Godot_v4.7.2-stable_win64_console.exe'
MIN_SIDE = 128


def _side(src: pathlib.Path) -> int:
    """the picture's shorter side in pixels (0 if it cannot be read)"""
    try:
        from PIL import Image
        with Image.open(src) as im:
            return min(im.size)
    except Exception:
        return 0


def _mirror() -> None:
    COPY.mkdir(parents=True, exist_ok=True)
    if not (COPY / '.godot').exists() and (SRC / '.godot').exists():
        shutil.copytree(SRC / '.godot', COPY / '.godot')           # (the first time: the imports already made)
    # /MIR: the same files (and gone the ones gone); /XD: not the pictures, not the cache, not data (a junction)
    r = subprocess.run(['robocopy', str(SRC), str(COPY), '/MIR', '/XD', str(SRC / 'shots'), str(SRC / '.godot'), str(SRC / 'data'),
                        str(COPY / '.godot'), str(COPY / 'data'), '/XJ', '/NFL', '/NDL', '/NJH', '/NJS', '/NP', '/R:2', '/W:1'],
                       capture_output=True, text=True)
    if r.returncode >= 8:                                           # (robocopy: 0-7 are kinds of success)
        sys.exit('robocopy failed (%d): %s' % (r.returncode, r.stdout[-2000:]))
    data = COPY / 'data'
    if not data.exists():
        subprocess.run(['cmd', '/c', 'mklink', '/J', str(data), str(SRC / 'data')], check=True, capture_output=True)


def _flip() -> tuple:
    """the copy's lossless 3D textures to VRAM compressed; returns (flipped now, compressed in all)"""
    flipped = total = 0
    for imp in COPY.rglob('*.import'):
        rel = imp.relative_to(COPY).as_posix()
        if rel.startswith('data/') or rel.startswith('.godot/'):
            continue
        text = imp.read_text(encoding='utf8')
        if 'importer="texture"' not in text or 'mipmaps/generate=true' not in text:
            continue
        if _side(imp.with_suffix('')) < MIN_SIDE:          # (left as godot/ has it: robocopy has just put it back)
            continue
        new = text.replace('compress/mode=0', 'compress/mode=2')
        if imp.name == 'normal.jpg.import' and rel.startswith('assets/texturas/'):
            new = re.sub(r'^compress/normal_map=\d', 'compress/normal_map=1', new, flags=re.M)
        if 'compress/mode=2' in new:
            total += 1
        if new != text:
            imp.write_text(new, encoding='utf8', newline='\n')
            flipped += 1
    return flipped, total


def prepare() -> pathlib.Path:
    _mirror()
    flipped, total = _flip()
    r = subprocess.run([GODOT, '--headless', '--path', str(COPY), '--import'], capture_output=True, text=True, encoding='utf8', errors='replace')
    if r.returncode != 0:
        print(r.stdout[-3000:], r.stderr[-3000:])
        sys.exit('the Android copy could not be imported')
    print('android copy: %s, %d textures compressed (%d rewritten now)' % (COPY, total, flipped))
    return COPY


if __name__ == '__main__':
    prepare()
