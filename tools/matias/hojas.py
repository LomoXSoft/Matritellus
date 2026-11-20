"""The sheets shown to the user of the house of the Calle de Matías Pérez 16 (guion/fotos/matias/).

    python tools/matias/hojas.py [SV_FOLDER]

01: Street View beside the game from the same spots (run first, SV_FOLDER made by tools/matias/capturas.py:
    tools/run_tests.py "$(python tools/merkocarry/vistas.py SV_FOLDER m0 m1 m2 m3 m0_up m1_up)").
    (m4 is left out: people stand in it. The far passer-by of m1 is blurred.)
02: the game (tools/run_tests.py matias): straight on, along the street both ways, its doorways close, the windows
    above, at night.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'matias')
os.makedirs(OUT, exist_ok=True)
sv = sys.argv[1] if len(sys.argv) > 1 else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()
BLUR = {'m1': [(296, 430, 344, 490)]}           # (in the 1024 x 640 picture: the passer-by far down the street)


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


def street(n):
    im = Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
    for box in BLUR.get(n, []):
        sx, sy = im.size[0] / 1024.0, im.size[1] / 640.0
        b = (int(box[0] * sx), int(box[1] * sy), int(box[2] * sx), int(box[3] * sy))
        im.paste(im.crop(b).filter(ImageFilter.GaussianBlur(9)), b)
    return im


if sv:
    rows = []
    for n, what in (('m0', 'de frente, desde la acera de enfrente (2024)'), ('m1', 'la calle hacia el oeste (2024)'),
                    ('m2', 'la calle hacia el este (2024)'), ('m3', 'desde el este, más lejos (2024)'),
                    ('m0_up', 'el piso de arriba y la cornisa (2024)'), ('m1_up', 'el piso de arriba desde el este (2024)')):
        rows.append(('Street View: ' + what, street(n)))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('De frente', shot('matias_frente')), ('Los huecos de abajo', shot('matias_bajo')),
                             ('Desde el oeste', shot('matias_oeste')), ('Desde el este', shot('matias_este')),
                             ('Las ventanas de arriba', shot('matias_arriba')), ('De noche', shot('matias_frente_noche'))], 800, 450, 2)
