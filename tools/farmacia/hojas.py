"""The sheets shown to the user of the pharmacy of the Calle Real and its neighbours (guion/fotos/farmacia_real/).

    python tools/farmacia/hojas.py SV_FOLDER        (the Street View pictures fetched by capturas.py)

01: Street View (November 2024) beside the game.   02: the game's own pictures (`tools/run_tests.py farmacia --window`).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'farmacia_real')
os.makedirs(OUT, exist_ok=True)
sv = sys.argv[1] if len(sys.argv) > 1 else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()


def fit(im, w, h):
    r = w / h
    if im.size[0] / im.size[1] > r:
        nw = int(im.size[1] * r); im = im.crop(((im.size[0] - nw) // 2, 0, (im.size[0] + nw) // 2, im.size[1]))
    else:
        nh = int(im.size[0] / r); im = im.crop((0, (im.size[1] - nh) // 2, im.size[0], (im.size[1] + nh) // 2))
    return im.resize((w, h), Image.LANCZOS)


def sheet(name, rows, w, h, cols):
    n = (len(rows) + cols - 1) // cols
    out = Image.new('RGB', (cols * w + (cols - 1) * 6, n * (h + 26)), (22, 22, 24))
    d = ImageDraw.Draw(out)
    for i, (label, im) in enumerate(rows):
        x, y = (i % cols) * (w + 6), (i // cols) * (h + 26)
        d.text((x + 6, y + 4), label, fill=(240, 240, 240), font=font)
        out.paste(fit(im, w, h), (x, y + 26))
    path = os.path.join(OUT, name)
    out.save(path, quality=90)
    print(path, out.size)


def shot(n):
    return Image.open(os.path.join(SHOTS, 'farmacia_' + n + '.png')).convert('RGB')


if sv:
    rows = []
    for n, g, what in (('X24_ne', 'esquina', 'la droguería, en la esquina de Colón'), ('A24_norte', 'farmacia_sur', 'la farmacia: el escaparate y las terrazas'),
                       ('N24_f', 'farmacia_norte', 'la farmacia: el portal y la mitad norte'), ('M24_f', 'ladrillo', 'la casa de ladrillo')):
        rows.append(('Street View, noviembre de 2024: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego', shot(g)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('La esquina, desde la calle Real peatonal', shot('esquina')), ('La droguería: puerta, reja y rótulo', shot('drogueria')),
                             ('La farmacia, mitad sur', shot('farmacia_sur')), ('La puerta de la farmacia', shot('puerta')),
                             ('La farmacia, mitad norte, y el portal', shot('farmacia_norte')), ('La casa de ladrillo', shot('ladrillo')),
                             ('El costado de la droguería en Colón', shot('colon')), ('Desde el aire', shot('aire'))], 800, 450, 2)
