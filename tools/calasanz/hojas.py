"""The sheets shown to the user of the nursery school of the Calle del Palo (guion/fotos/calasanz/).

    python tools/calasanz/hojas.py SV_FOLDER        (the Street View pictures fetched by capturas.py)

01: Street View (May 2009, March 2013) beside the game from the same spots (run first: tools/run_tests.py with
    vistas_sv.py B13_ne A09_ne C13_ne C13_n).   02: the game's own pictures (`tools/run_tests.py calasanz --window`).
03: the mural of the doves on the end wall: Street View of October 2019 beside the game from the same spot, and the
    game's wall from close by and from the pavement (run first: tools/run_tests.py "<vistas_sv.py D19_mural>;" plus
    "cz_mural_cerca:31.0,-3.4,1.8,23.4,-3.4,1.8,40;cz_mural_calle:31.2,9.1,1.9,23.4,-3.4,1.9,45" --window).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'calasanz')
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
    for n, what in (('B13_ne', 'Street View, marzo de 2013: la fachada, de frente'), ('A09_ne', 'Street View, mayo de 2009: el patio de los juegos'),
                    ('C13_ne', 'Street View, marzo de 2013: el testero y la caseta'), ('C13_n', 'Street View, marzo de 2013: calle arriba')):
        rows.append((what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_cz_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('La escuela, de frente', shot('calasanz_frente')), ('La puerta, el rótulo y el arco pintado', shot('calasanz_puerta')),
                             ('El patio de los juegos, desde la esquina', shot('calasanz_juegos')), ('La torre, el tobogán, los neumáticos, la casita', shot('calasanz_juegos_cerca')),
                             ('El testero y la rayuela, ya sin la caseta', shot('calasanz_caseta')), ('Las palomas del testero', shot('calasanz_mural')),
                             ('El arco y el porche', shot('calasanz_arco')), ('Desde el aire', shot('calasanz_aire'))], 800, 450, 2)
if sv and os.path.exists(os.path.join(sv, 'D19_mural.jpg')) and os.path.exists(os.path.join(SHOTS, 'vista_cz_D19_mural.png')):
    sheet('03_mural_palomas.jpg', [('Street View, octubre de 2019: el mural del testero', Image.open(os.path.join(sv, 'D19_mural.jpg')).convert('RGB')),
                                   ('El juego, desde el mismo sitio', shot('vista_cz_D19_mural')),
                                   ('El mural, de cerca', shot('vista_cz_mural_cerca')), ('Desde la acera, sin la caseta', shot('vista_cz_mural_calle'))], 800, 500, 2)
