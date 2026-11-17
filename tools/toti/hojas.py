"""The sheets shown to the user of the Pizzería Toti (guion/fotos/toti/).

    python tools/toti/hojas.py [SV_FOLDER]            (the Street View pictures fetched by capturas.py)

01: Street View (November 2024) beside the game from the same spots (run first: tools/run_tests.py
    "$(python tools/merkocarry/vistas.py SV_FOLDER b24 a24_sur b24_calle c24_norte b24_cerca)").
02: the game (tools/run_tests.py toti): the front, the terrace, the awning and the board, the room through the glass,
    open, shut and at night.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'toti')
os.makedirs(OUT, exist_ok=True)
sv = sys.argv[1] if len(sys.argv) > 1 else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()
BLUR = {}                     # (fraction boxes of people in a picture, if any: no faces shown)


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
    return Image.open(os.path.join(SHOTS, n + '.png')).convert('RGB')


def sv_pic(n):
    im = Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
    for b in BLUR.get(n, []):
        box = tuple(int(v * s) for v, s in zip(b, im.size * 2))
        im.paste(im.crop(box).resize((4, 4)).resize((box[2] - box[0], box[3] - box[1])).filter(ImageFilter.GaussianBlur(6)), box[:2])
    return im


if sv:
    rows = []
    for n, what in (('b24', 'la pizzería de enfrente'), ('b24_cerca', 'el toldo y el rótulo'), ('a24_sur', 'desde el norte, la terraza en la calle'),
                    ('b24_calle', 'la terraza con su valla'), ('c24_norte', 'desde el sur')):
        rows.append(('Street View 2024: ' + what, sv_pic(n)))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('De frente, abierta', shot('toti_frente')), ('La terraza', shot('toti_terraza')),
                             ('El toldo y el rótulo', shot('toti_toldo')), ('Por dentro, a través del cristal', shot('toti_dentro')),
                             ('Desde el norte', shot('toti_norte')), ('Desde el sur', shot('toti_sur')),
                             ('El portal y la cochera', shot('toti_portal')), ('Los pisos de arriba', shot('toti_arriba')),
                             ('Cerrada (por la mañana)', shot('toti_frente_cerrado')), ('De noche, abierta', shot('toti_frente_noche')),
                             ('La terraza de noche', shot('toti_terraza_noche')), ('Desde el aire', shot('toti_aire'))], 800, 450, 2)
