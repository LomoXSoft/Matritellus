"""The sheets shown to the user of the pizza house ("Todopizza") (guion/fotos/todopizza/).

    python tools/todopizza/hojas.py SV_FOLDER        (the Street View pictures fetched by capturas.py)

01: Street View (November 2024) beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/todopizza/vistas.py SV_FOLDER o1 o1_zoom n2 e1_zoom)").
02: the game's own pictures (tools/run_tests.py todopizza).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'todopizza')
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
    return Image.open(os.path.join(SHOTS, n + '.png')).convert('RGB')


if sv:
    rows = []
    for n, what in (('o1', 'desde la carretera antigua'), ('o1_zoom', 'el frente de cristal y las puertas'), ('n2', 'el lado norte'), ('e1_zoom', 'la trasera: puerta, tubo, depósito')):
        rows.append(('Street View, noviembre de 2024: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('Desde la carretera antigua', shot('todopizza_frente')), ('Las puertas y el rótulo', shot('todopizza_puerta')),
                             ('Por el cristal: mostrador, carta y mesas', shot('todopizza_dentro')), ('El cartel de la esquina', shot('todopizza_cartel')),
                             ('El jardín de rocas y el lado norte', shot('todopizza_esquina')), ('La trasera y los contenedores', shot('todopizza_trasera')),
                             ('Junto al Mercamona', shot('todopizza_con_mercamona')), ('Desde el aire', shot('todopizza_aire'))], 800, 450, 2)
