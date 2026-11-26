"""Makes the Linux package of the game (SteamOS on a Steam Machine or a Steam Deck, or any x86_64 Linux):
dist/Matritellus-Linux.tar.gz, one file to pass around.

    python tools/make_linux.py

What it does:
  1. Godot exports the "Linux" preset (godot/export_presets.cfg) with the Linux template installed on this machine:
     Matritellus.x86_64 (the engine) and Matritellus.pck (the game);
  2. puts beside them the icon, the radio stations (radio1, radio2... with their music) and the ready-cut ground (so the
     first start is not slow), with instalar.sh, desinstalar.sh and LEEME.txt;
  3. packs that folder into a .tar.gz, the programs and scripts marked as runnable (a zip would lose that).

On the machine: unpack it, run instalar.sh (from a terminal or by double-clicking in Dolphin, in SteamOS's desktop
mode). It goes to ~/.local/share/Matritellus, with an entry in the applications menu; then Steam > Add a non-Steam
game > Matritellus, and it can be played from Game Mode with the pad.
"""
import datetime, io, os, shutil, subprocess, sys, tarfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GODOT = r'C:\Users\luis_\Fable\tools\godot\Godot_v4.7.2-stable_win64_console.exe'
DIST = os.path.join(ROOT, 'dist')
GAME = os.path.join(DIST, 'Matritellus-Linux')
OUT = os.path.join(DIST, 'Matritellus-Linux.tar.gz')
USERDATA = os.path.join(os.environ.get('APPDATA', ''), 'Godot', 'app_userdata', 'Matritellus')

INSTALAR = r'''#!/bin/bash
# Instala Matritellus en ~/.local/share/Matritellus, con su entrada en el menú de aplicaciones.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.local/share/Matritellus"
DATA="$HOME/.local/share/godot/app_userdata/Matritellus"
mkdir -p "$DEST" "$DATA" "$HOME/.local/share/applications"
rm -f "$DEST/Matritellus.x86_64"
rm -rf "$DEST/radio"
cp -r "$HERE/Matritellus.x86_64" "$HERE/Matritellus.pck" "$HERE/icon.png" "$HERE/radio" "$HERE/desinstalar.sh" "$HERE/LEEME.txt" "$DEST/"
chmod +x "$DEST/Matritellus.x86_64" "$DEST/desinstalar.sh"
[ -f "$HERE/ground.cache" ] && cp "$HERE/ground.cache" "$DATA/ground.cache"     # el suelo ya cortado: el primer arranque no tarda
cat > "$HOME/.local/share/applications/matritellus.desktop" <<EOD
[Desktop Entry]
Type=Application
Name=Matritellus
Comment=Madridejos, como nunca lo has visto
Exec="$DEST/Matritellus.x86_64"
Path=$DEST
Icon=$DEST/icon.png
Terminal=false
Categories=Game;
EOD
echo
echo "Matritellus instalado en $DEST"
echo "Para jugar desde el Modo Juego: Steam > Añadir un juego que no es de Steam > Matritellus."
command -v notify-send >/dev/null && notify-send "Matritellus" "Instalado. Añádelo a Steam como juego que no es de Steam." || true
'''

DESINSTALAR = r'''#!/bin/bash
# Quita Matritellus. Las partidas guardadas se quedan (en ~/.local/share/godot/app_userdata/Matritellus) salvo que
# se diga --todo.
DEST="$HOME/.local/share/Matritellus"
rm -f "$HOME/.local/share/applications/matritellus.desktop"
rm -rf "$DEST"
if [ "$1" = "--todo" ]; then
  rm -rf "$HOME/.local/share/godot/app_userdata/Matritellus"
  echo "Matritellus quitado, partidas incluidas."
else
  echo "Matritellus quitado. Tus partidas siguen guardadas (desinstalar.sh --todo las borra también)."
fi
'''

LEEME = '''Matritellus para Linux (SteamOS: Steam Machine o Steam Deck; o cualquier Linux de 64 bits, x86_64)
=====================================================================================

Instalar
  1. Descomprime Matritellus-Linux.tar.gz (en SteamOS: en el Modo Escritorio, clic derecho > Extraer).
  2. Ejecuta instalar.sh (doble clic, o desde una terminal: ./instalar.sh).
  3. En Steam: Añadir un juego > Añadir un juego que no es de Steam > Matritellus. Ya sale en el Modo Juego.

Se juega con el mando. Las partidas se guardan en ~/.local/share/godot/app_userdata/Matritellus.

Sin instalar: ./Matritellus.x86_64 desde esta misma carpeta también funciona.

Quitarlo: ~/.local/share/Matritellus/desinstalar.sh (deja las partidas; con --todo las borra también).

Versión del %s.
'''

def run(args):
    print('>', ' '.join(os.path.basename(a) if os.path.isabs(a) else a for a in args))
    r = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    out = r.stdout.decode('utf8', 'replace')
    if r.returncode != 0:
        print(out[-3000:])
        sys.exit('failed: ' + os.path.basename(args[0]))
    return out

def assemble():
    if os.path.isdir(GAME):
        shutil.rmtree(GAME)
    os.makedirs(GAME)
    run([GODOT, '--headless', '--path', os.path.join(ROOT, 'godot'), '--export-release', 'Linux', os.path.join(GAME, 'Matritellus.x86_64')])
    for need in ('Matritellus.x86_64', 'Matritellus.pck'):
        if not os.path.exists(os.path.join(GAME, need)):
            sys.exit('export left no ' + need)
    from PIL import Image
    Image.open(os.path.join(ROOT, 'godot', 'assets', 'logo.png')).convert('RGBA').resize((256, 256), Image.LANCZOS).save(os.path.join(GAME, 'icon.png'))
    radio = os.path.join(ROOT, 'godot', 'radio')
    os.makedirs(os.path.join(GAME, 'radio'))
    for extra in ('LEEME.txt', 'entrada.txt'):
        if os.path.exists(os.path.join(radio, extra)):
            shutil.copy2(os.path.join(radio, extra), os.path.join(GAME, 'radio', extra))
    n = 1
    while os.path.isdir(os.path.join(radio, 'radio%d' % n)):          # (the stations in use: not the ones parked in _reserva)
        shutil.copytree(os.path.join(radio, 'radio%d' % n), os.path.join(GAME, 'radio', 'radio%d' % n))
        n += 1
    cache = os.path.join(USERDATA, 'ground.cache')
    if os.path.exists(cache):
        shutil.copy2(cache, os.path.join(GAME, 'ground.cache'))
    print('assembled', GAME, 'with', n - 1, 'stations')

def pack():
    today = datetime.date.today().strftime('%d/%m/%Y')
    runnable = {'Matritellus.x86_64', 'instalar.sh', 'desinstalar.sh'}
    with tarfile.open(OUT, 'w:gz', compresslevel=6) as t:
        def add_text(name, text):
            data = text.replace('\r\n', '\n').encode('utf8')
            info = tarfile.TarInfo('Matritellus/' + name)
            info.size = len(data)
            info.mode = 0o755 if name in runnable else 0o644
            info.mtime = int(datetime.datetime.now().timestamp())
            t.addfile(info, io.BytesIO(data))
        for folder, dirs, files in os.walk(GAME):
            dirs.sort()
            for name in sorted(files):
                full = os.path.join(folder, name)
                rel = os.path.relpath(full, GAME).replace('\\', '/')
                info = t.gettarinfo(full, 'Matritellus/' + rel)
                info.mode = 0o755 if rel in runnable else 0o644
                info.uid = info.gid = 1000
                info.uname = info.gname = ''
                with open(full, 'rb') as f:
                    t.addfile(info, f)
        add_text('instalar.sh', INSTALAR)
        add_text('desinstalar.sh', DESINSTALAR)
        add_text('LEEME.txt', LEEME % today)
    print('%s  (%.0f MB)' % (OUT, os.path.getsize(OUT) / 2 ** 20))

if __name__ == '__main__':
    assemble()
    pack()
