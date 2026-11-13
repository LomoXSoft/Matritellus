"""Makes the Windows installer of the game: dist/Matritellus-Instalador.exe (one file to pass around).

    python tools/make_installer.py            export, assemble, pack
    python tools/make_installer.py --keep     pack what is already in dist/Matritellus (no new export)

What it does:
  1. exports the game's data from the Godot project (godot/export_presets.cfg) to dist/Matritellus/Matritellus.pck;
  2. puts beside it the engine as Matritellus.exe, the icon and the radio stations (radio1, radio2... with their music);
  3. zips that folder, with the uninstaller and the ready-cut ground (so the first start is not slow), and compiles
     tools/instalador/Instalador.cs around the zip with the C# compiler that comes with Windows.

The engine that goes in is the same Godot program the game is developed and tested with: the export templates
installed on this machine are only the Linux ones. With the Windows template (windows_release_x86_64.exe from Godot's
export templates) the game would be some 90 MB smaller; point TEMPLATE at it if it is ever installed.
"""
import datetime, os, shutil, subprocess, sys, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GODOT = r'C:\Users\luis_\Fable\tools\godot\Godot_v4.7.2-stable_win64.exe'
GODOT_CONSOLE = r'C:\Users\luis_\Fable\tools\godot\Godot_v4.7.2-stable_win64_console.exe'
TEMPLATE = os.path.join(os.environ.get('APPDATA', ''), 'Godot', 'export_templates', '4.7.2.stable', 'windows_release_x86_64.exe')
CSC = r'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
DIST = os.path.join(ROOT, 'dist')
GAME = os.path.join(DIST, 'Matritellus')
BUILD = os.path.join(DIST, '_build')
USERDATA = os.path.join(os.environ.get('APPDATA', ''), 'Godot', 'app_userdata', 'Matritellus')

def run(args, **kw):
    print('>', ' '.join(os.path.basename(a) if os.path.isabs(a) else a for a in args))
    r = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, **kw)
    out = r.stdout.decode('utf8', 'replace')
    if r.returncode != 0:
        print(out[-3000:])
        sys.exit('failed: ' + os.path.basename(args[0]))
    return out

def assemble():
    if os.path.isdir(GAME):
        shutil.rmtree(GAME)
    os.makedirs(GAME)
    run([GODOT_CONSOLE, '--headless', '--path', os.path.join(ROOT, 'godot'), '--export-pack', 'Windows Desktop', os.path.join(GAME, 'Matritellus.pck')])
    shutil.copy2(TEMPLATE if os.path.exists(TEMPLATE) else GODOT, os.path.join(GAME, 'Matritellus.exe'))
    shutil.copy2(os.path.join(ROOT, 'godot', 'icon.ico'), os.path.join(GAME, 'Matritellus.ico'))
    radio = os.path.join(ROOT, 'godot', 'radio')
    os.makedirs(os.path.join(GAME, 'radio'))
    shutil.copy2(os.path.join(radio, 'LEEME.txt'), os.path.join(GAME, 'radio', 'LEEME.txt'))
    if os.path.exists(os.path.join(radio, 'entrada.txt')):            # which tunes the game may open with
        shutil.copy2(os.path.join(radio, 'entrada.txt'), os.path.join(GAME, 'radio', 'entrada.txt'))
    n = 1
    while os.path.isdir(os.path.join(radio, 'radio%d' % n)):          # (the stations in use: not the ones parked in _reserva)
        shutil.copytree(os.path.join(radio, 'radio%d' % n), os.path.join(GAME, 'radio', 'radio%d' % n))
        n += 1
    print('assembled', GAME, 'with', n - 1, 'stations')

def pack():
    os.makedirs(BUILD, exist_ok=True)
    today = datetime.date.today()
    version = '%d.%d.%d.0' % (today.year, today.month, today.day)
    src = os.path.join(HERE, 'instalador', 'Instalador.cs')
    info = os.path.join(BUILD, 'version.cs')
    with open(info, 'w', encoding='utf8') as f:
        f.write('[assembly: System.Reflection.AssemblyVersion("%s")]\n[assembly: System.Reflection.AssemblyTitle("Matritellus")]\n'
                '[assembly: System.Reflection.AssemblyProduct("Matritellus")]\n[assembly: System.Reflection.AssemblyCompany("LomoXGames")]\n' % version)
    ico = os.path.join(ROOT, 'godot', 'icon.ico')
    refs = ['/r:System.dll', '/r:System.Drawing.dll', '/r:System.Windows.Forms.dll', '/r:System.IO.Compression.dll']
    # the uninstaller first: it goes inside the zip
    un = os.path.join(BUILD, 'Desinstalar.exe')
    run([CSC, '/nologo', '/codepage:65001', '/target:winexe', '/optimize+', '/define:UNINSTALL', '/win32icon:' + ico, '/out:' + un] + refs + [src, info])
    # the zip
    payload = os.path.join(BUILD, 'payload.zip')
    total = 0
    with zipfile.ZipFile(payload, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for folder, _, files in os.walk(GAME):
            for name in sorted(files):
                full = os.path.join(folder, name)
                rel = os.path.relpath(full, GAME).replace('\\', '/')
                if rel.lower().endswith('.console.exe') or rel.startswith('shots/'):
                    continue
                # (music is compressed already: stored as it is)
                z.write(full, rel, zipfile.ZIP_STORED if rel.lower().endswith(('.ogg', '.mp3', '.png')) else zipfile.ZIP_DEFLATED)
                total += os.path.getsize(full)
        z.write(un, 'Desinstalar.exe')
        cache = os.path.join(USERDATA, 'ground.cache')
        if os.path.exists(cache):                                     # the ground, cut already for this map
            z.write(cache, '_userdata/ground.cache', zipfile.ZIP_STORED)
            total += os.path.getsize(cache)
    print('payload: %.0f MB unpacked, %.0f MB zipped' % (total / 2 ** 20, os.path.getsize(payload) / 2 ** 20))
    # a small logo for the window
    from PIL import Image
    logo = os.path.join(BUILD, 'logo.png')
    Image.open(os.path.join(ROOT, 'godot', 'assets', 'logo.png')).convert('RGBA').resize((264, 264), Image.LANCZOS).save(logo)
    out = os.path.join(DIST, 'Matritellus-Instalador.exe')
    run([CSC, '/nologo', '/codepage:65001', '/target:winexe', '/optimize+', '/platform:x64', '/win32icon:' + ico, '/out:' + out,
         '/resource:' + payload + ',payload.zip', '/resource:' + logo + ',logo.png'] + refs + [src, info])
    print('%s  (%.0f MB, version %s)' % (out, os.path.getsize(out) / 2 ** 20, version))

if __name__ == '__main__':
    if '--keep' not in sys.argv:
        assemble()
    pack()
