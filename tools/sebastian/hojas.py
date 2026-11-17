"""The sheets shown to the user of the hermitage of San Sebastián and its park (guion/fotos/sebastian/).

    python tools/sebastian/hojas.py [SV_FOLDER] [P360_FOLDER]

01: Street View beside the game from the same spots (run first: tools/run_tests.py
    "$(python tools/merkocarry/vistas.py SV_FOLDER c1 c2 c3 c0 cm cn_er p3 p6_er p2 n1 c4)").
02: the game (tools/run_tests.py sebastian): its front, porch, side and terrace, from the north, the square, the park,
    at night, from the air.
03: the round picture by the porch beside the game (only in the scratchpad: it is a private person's).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'sebastian')
os.makedirs(OUT, exist_ok=True)
sv = sys.argv[1] if len(sys.argv) > 1 else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()
BLUR = {'c2': [(0.42, 0.55, 0.5, 0.75)], 'c3': [(0.22, 0.6, 0.3, 0.78)], 'c1': [(0.6, 0.58, 0.66, 0.72)]}   # (passers-by: no faces shown)


def fit(im, w, h):
    r = w / h
    if im.size[0] / im.size[1] > r:
        nw = int(im.size[1] * r); im = im.crop(((im.size[0] - nw) // 2, 0, (im.size[0] + nw) // 2, im.size[1]))
    else:
        nh = int(im.size[0] / r); im = im.crop((0, (im.size[1] - nh) // 2, im.size[0], (im.size[1] + nh) // 2))
    return im.resize((w, h), Image.LANCZOS)


def sheet(name, rows, w, h, cols, where=None):
    n = (len(rows) + cols - 1) // cols
    out = Image.new('RGB', (cols * w + (cols - 1) * 6, n * (h + 26)), (22, 22, 24))
    d = ImageDraw.Draw(out)
    for i, (label, im) in enumerate(rows):
        x, y = (i % cols) * (w + 6), (i // cols) * (h + 26)
        d.text((x + 6, y + 4), label, fill=(240, 240, 240), font=font)
        out.paste(fit(im, w, h), (x, y + 26))
    path = os.path.join(where or OUT, name)
    out.save(path, quality=90)
    print(path, out.size)


def shot(n):
    return Image.open(os.path.join(SHOTS, n + '.png')).convert('RGB')


def sv_pic(n):
    im = Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
    for b in BLUR.get(n, []):
        box = (int(b[0] * im.size[0]), int(b[1] * im.size[1]), int(b[2] * im.size[0]), int(b[3] * im.size[1]))
        im.paste(im.crop(box).resize((3, 3)).resize((box[2] - box[0], box[3] - box[1])).filter(ImageFilter.GaussianBlur(6)), box[:2])
    return im


if sv:
    rows = []
    for n, what in (('c1', 'la fachada desde la esquina (2024)'), ('c0', 'el parque y la fachada desde el cruce (2024)'), ('c2', 'el costado y la terraza (2024)'),
                    ('c3', 'la capillita sobre la calle (2024)'), ('c4', 'la terraza hacia el sur (2024)'), ('n1', 'desde el norte (2019)'),
                    ('cn_er', 'la esquina del parque (2024)'), ('p6_er', 'el parque hacia la ermita (2024)'), ('p3', 'el parque y la pérgola (2024)'),
                    ('p2', 'la pérgola desde el oeste (2024)')):
        rows.append(('Street View: ' + what, sv_pic(n)))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('La fachada y el pórtico', shot('sebastian_frente')), ('Bajo el pórtico', shot('sebastian_portico')),
                             ('La capillita y la terraza, por la calle', shot('sebastian_costado')), ('La terraza', shot('sebastian_terraza')),
                             ('Desde el norte', shot('sebastian_norte')), ('La plaza redonda', shot('sebastian_plaza')),
                             ('El parque', shot('sebastian_parque')), ('La pérgola y la esquina', shot('sebastian_pergola')),
                             ('Desde el cruce', shot('sebastian_esquina')), ('De noche', shot('sebastian_frente_noche')),
                             ('Desde el aire', shot('sebastian_aire')), ('Desde el aire, por el noreste', shot('sebastian_aire_ne'))], 800, 450, 2)
p360 = sys.argv[2] if len(sys.argv) > 2 else ''
if p360:
    sheet('03_foto_360_y_juego.jpg', [('Foto 360 junto al pórtico: la puerta', Image.open(os.path.join(p360, 'ya0.jpg')).convert('RGB')),
                                      ('El juego', shot('sebastian_portico')),
                                      ('Foto 360: la plaza redonda y la pérgola', Image.open(os.path.join(p360, 'ya225.jpg')).convert('RGB')),
                                      ('El juego', shot('sebastian_plaza'))], 700, 440, 2, where=os.path.dirname(os.path.abspath(p360)))
