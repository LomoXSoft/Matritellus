"""The sheets shown to the user of the house on the corner of the Salvador and Ramón y Cajal ("Salvador 2";
guion/fotos/salvador2/).

    python tools/salvador2/hojas.py [SV_FOLDER]            (the Street View pictures fetched by capturas.py)

01: Street View beside the game from the same spots (run first: tools/run_tests.py
    "$(python tools/merkocarry/vistas.py SV_FOLDER e24 j24 a24 e24_sal m13)").
02: the game (tools/run_tests.py salvador2): from the crossroads, up both streets, its bay, its doors, at night, from
    the air.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'salvador2')
os.makedirs(OUT, exist_ok=True)
sv = sys.argv[1] if len(sys.argv) > 1 else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()
BLUR = {'j24': [(0.962, 0.6, 1.0, 0.76)]}     # (fractions of the picture: a passer-by, no face shown)


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
        box = (int(b[0] * im.size[0]), int(b[1] * im.size[1]), int(b[2] * im.size[0]), int(b[3] * im.size[1]))
        im.paste(im.crop(box).resize((3, 3)).resize((box[2] - box[0], box[3] - box[1])).filter(ImageFilter.GaussianBlur(6)), box[:2])
    return im


if sv:
    rows = []
    for n, what in (('e24', 'desde el norte del cruce (2024)'), ('j24', 'desde la calle de la Plaza (2024)'), ('a24', 'su fachada a Ramón y Cajal (2024)'),
                    ('e24_sal', 'su fachada al Salvador (2024)'), ('m13', 'el Salvador, de cerca (2013)')):
        rows.append(('Street View: ' + what, sv_pic(n)))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('Desde el cruce', shot('salvador2_esquina')), ('El mirador de la esquina', shot('salvador2_mirador')),
                             ('Su fachada a Ramón y Cajal', shot('salvador2_cajal_frente')), ('La puerta de Ramón y Cajal', shot('salvador2_entrada')),
                             ('Su fachada al Salvador', shot('salvador2_salvador_frente')), ('Bajando por el Salvador', shot('salvador2_salvador')),
                             ('Desde Ramón y Cajal, con la Toti', shot('salvador2_cajal')), ('Desde el aire', shot('salvador2_aire')),
                             ('De noche, desde el cruce', shot('salvador2_esquina_noche')), ('De noche, desde Ramón y Cajal', shot('salvador2_cajal_noche'))], 800, 450, 2)
