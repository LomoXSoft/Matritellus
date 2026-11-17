"""The sheets shown to the user of the little hermitage of San Cristóbal (guion/fotos/cristobal/).

    python tools/cristobal/hojas.py [SV_FOLDER]

01: Street View beside the game from the same spots (run first: tools/run_tests.py
    "$(python tools/merkocarry/vistas.py SV_FOLDER r1_z r1_21_z r2_21 r4_21 o1 o2_z o3 o5_z)").
02: the game (tools/run_tests.py cristobal): from the old road, its door and yard, from Ortega y Gasset, from the north,
    at night, from the air.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'cristobal')
os.makedirs(OUT, exist_ok=True)
sv = sys.argv[1] if len(sys.argv) > 1 else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()
BLUR = {}                                       # (no passers-by in these views)


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


if sv:
    rows = []
    for n, what in (('r1_z', 'desde la carretera vieja (2024)'), ('r1_21_z', 'desde la carretera vieja (2021)'), ('r2_21', 'la esquina con Ortega y Gasset (2021)'),
                    ('r4_21', 'desde el norte por la carretera (2021)'), ('o1', 'por Ortega y Gasset, el hastial (2013)'), ('o2_z', 'la puerta y su reja (2013)'),
                    ('o3', 'Ortega y Gasset hacia la carretera (2013)'), ('o5_z', 'el lado de la puerta (2013)')):
        rows.append(('Street View: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('Desde la carretera vieja', shot('cristobal_carretera')), ('La puerta y el patinillo', shot('cristobal_puerta')),
                             ('Por Ortega y Gasset', shot('cristobal_ortega')), ('Ortega y Gasset, desde el este', shot('cristobal_ortega_este')),
                             ('Ortega y Gasset, desde el oeste', shot('cristobal_ortega_oeste')), ('Desde el norte', shot('cristobal_norte')),
                             ('De noche', shot('cristobal_carretera_noche')), ('Desde el aire', shot('cristobal_aire'))], 800, 450, 2)
