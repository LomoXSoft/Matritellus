"""The sheets shown to the user of the Tricornios' roundabout (guion/fotos/rotonda_tricornios/).

    python tools/rotonda/hojas.py [SV_FOLDER]        (the Street View pictures fetched by capturas.py)

01: Street View (November 2024, before the flag and the monolith) beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/rotonda/vistas.py SV_FOLDER w_cerca sw se nne_cerca)").
02: the game's own pictures (tools/run_tests.py rotonda).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'rotonda_tricornios')
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


def whole(im, w, h):
    """the whole picture on a dark ground of that shape (fit() would cut a long one)"""
    r = min(w * 0.92 / im.size[0], h * 0.92 / im.size[1])
    im = im.resize((int(im.size[0] * r), int(im.size[1] * r)), Image.LANCZOS)
    out = Image.new('RGB', (w, h), (40, 40, 44))
    out.paste(im, ((w - im.size[0]) // 2, (h - im.size[1]) // 2))
    return out


def shot(n):
    return Image.open(os.path.join(SHOTS, n + '.png')).convert('RGB')


def pairs(name, views):
    rows = []
    for n, what in views:
        rows.append(('Street View: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet(name, rows, 800, 500, 2)


if sv:
    pairs('01_street_view_y_juego.jpg', (('w_cerca', 'desde el oeste (2024: aún sin bandera ni monolito)'), ('sw', 'desde el suroeste'), ('se', 'desde el sureste'), ('nne_cerca', 'desde el norte')))
sheet('02_en_el_juego.jpg', [('Como en tu foto', shot('rotonda_como_la_foto')), ('El monolito', shot('rotonda_monolito')),
                             ('La placa', shot('rotonda_placa')), ('La bandera', shot('rotonda_bandera')),
                             ('Desde el sur', shot('rotonda_desde_sur')), ('Desde el aire', shot('rotonda_aire')),
                             ('De noche', shot('rotonda_noche_como_la_foto')), ('Desde el oeste', shot('rotonda_desde_oeste'))], 800, 450, 2)
