"""Photograph | game, side by side, from the cameras fitted by encaja.py.

    python tools/petril/pareja.py out.jpg FOTOS name[=file[:x0,y0,x1,y1]] ...

FOTOS: the folder with the real photographs (they are other people's, so they are not kept in the repository).
name: a camera in tools/petril/vistas/<name>.json; its photograph is FOTOS/REF_<name>.jpg unless `=file` says
another, and its content the box 0,34,800,566 unless `:x0,y0,x1,y1` says another (the size given to encaja.py).
The game's picture is godot/shots/vista_pt_<name>.png (the self-test's --vistas, with the "view" of that json).
Also writes, beside out.jpg, juego_<name>.jpg: the game's picture cut to the photograph's frame and size, so that
color.py can measure the same patch in both."""
import sys, json, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
out = sys.argv[1]; fotos = sys.argv[2]
rows = []
for a in sys.argv[3:]:
    n = a.split('=')[0]
    photo = os.path.join(fotos, 'REF_%s.jpg' % n); box = (0, 34, 800, 566)
    if '=' in a:
        rest = a.split('=', 1)[1]
        photo = os.path.join(fotos, rest.split(':')[0])
        if ':' in rest: box = tuple(int(v) for v in rest.split(':')[1].split(','))
    j = json.load(open(os.path.join(HERE, 'vistas', '%s.json' % n)))
    real = Image.open(photo).convert('RGB').crop(box)
    game = Image.open(os.path.join(SHOTS, 'vista_pt_%s.png' % n)).convert('RGB')
    c = j['crop']
    game = game.crop((int(round(c[0])), int(round(c[1])), int(round(c[2])), int(round(c[3])))).resize(real.size, Image.LANCZOS)
    game.save(os.path.join(os.path.dirname(os.path.abspath(out)), 'juego_%s.jpg' % n), quality=95)
    rows.append((n, real, game))
w = 640
try: font = ImageFont.truetype('arial.ttf', 17)
except Exception: font = ImageFont.load_default()
hs = [int(w * r[1].height / r[1].width) for r in rows]
sheet = Image.new('RGB', (2 * w + 6, sum(hs) + 26 * len(rows)), (24, 24, 26)); d = ImageDraw.Draw(sheet)
y = 0
for (n, real, game), h in zip(rows, hs):
    sheet.paste(real.resize((w, h), Image.LANCZOS), (0, y + 24)); sheet.paste(game.resize((w, h), Image.LANCZOS), (w + 6, y + 24))
    d.text((6, y + 3), 'foto real  ' + n, fill=(240, 240, 240), font=font); d.text((w + 12, y + 3), 'juego', fill=(240, 240, 240), font=font)
    y += h + 26
sheet.save(out, quality=88); print(out, sheet.size)
