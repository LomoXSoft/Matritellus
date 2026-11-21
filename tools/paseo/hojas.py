"""The sheets shown to the user of the park of the Paseo del Cristo (guion/fotos/paseo/).

    python tools/paseo/hojas.py [SV_FOLDER] [foto=PHOTO.jpg]

01: Street View beside the game from the same spots (run first, SV_FOLDER made by tools/paseo/capturas.py:
    tools/run_tests.py "$(python tools/merkocarry/vistas.py SV_FOLDER c03_n c04_n c06_n c09_n c12_n c16_n p01_e p05_e
    p09_e p13_e p01_n p11_n p13_n)"). The 2013 cameras walk the park's own line (a man's height: the views are
    taken 2.5 m up all the same).
02: the game (tools/run_tests.py paseo): from the corner of the Calle de los Arcos, down the walk, from the Paseo, the
    square of the crossing path, from the east end, the slate close to, from the air, at night. With foto=, the
    user's own picture of the corner (21 November 2026, from Google Maps on the phone; NOT kept in the repository)
    goes first, beside the game's.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'paseo')
os.makedirs(OUT, exist_ok=True)
args = [a for a in sys.argv[1:] if not a.startswith('foto=')]
foto = ([a[5:] for a in sys.argv[1:] if a.startswith('foto=')] or [''])[0]
sv = args[0] if args else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()
BLUR = {}                   # (in the 1600 x 1000 picture: passers-by)


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
        im.paste(im.crop(box).filter(ImageFilter.GaussianBlur(12)), box)
    return im


if sv:
    rows = []
    for n, what in (('c03_n', 'la esquina oeste y el parterre de cipreses (2024)'), ('c04_n', 'la piedra y el tronco tallado (2024)'),
                    ('c06_n', 'los céspedes y la tapia blanca (2024)'), ('c09_n', 'la plaza del cruce (2024)'),
                    ('c12_n', 'los céspedes del tramo medio (2024)'), ('c16_n', 'el calvario, al este (2024)'),
                    ('p01_e', 'el paseo desde su arranque (2013)'), ('p05_e', 'el paseo, tramo oeste (2013)'),
                    ('p09_e', 'el paseo hacia la ermita (2013)'), ('p13_e', 'el tramo este (2013)'),
                    ('p01_n', 'la casa de los arcos y las muelas (2013)'), ('p11_n', 'el murete con verja del callejón (2013)'),
                    ('p13_n', 'la rocalla y el sauce (2013)')):
        rows.append(('Street View: ' + what, street(n)))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
rows = []
if foto:
    rows.append(('Tu foto: la esquina de la Calle de los Arcos', Image.open(foto).convert('RGB').crop((0, 160, 1272, 1060))))
    rows.append(('El juego, desde cerca de allí', shot('paseo_esquina')))
else:
    rows.append(('Desde la esquina de la Calle de los Arcos', shot('paseo_esquina')))
rows += [('El paseo desde su arranque, hacia la ermita', shot('paseo_oeste')), ('Desde el Paseo', shot('paseo_calle')),
         ('La plaza del cruce', shot('paseo_cruce')), ('Desde el extremo este', shot('paseo_este')),
         ('Las losas y un banco, de cerca', shot('paseo_losas')), ('Desde el aire', shot('paseo_aire')),
         ('De noche', shot('paseo_oeste_noche'))]
sheet('02_en_el_juego.jpg', rows, 800, 450, 2)
