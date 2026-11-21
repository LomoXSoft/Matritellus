"""The sheets shown to the user of the hermitage of the Cristo del Prado (guion/fotos/cristoprado/).

    python tools/cristoprado/hojas.py [SV_FOLDER]

01: Street View beside the game from the same spots (run first, SV_FOLDER made by tools/cristoprado/capturas.py:
    tools/run_tests.py "$(python tools/merkocarry/vistas.py SV_FOLDER p1_f s2_13 s1_19 s3 s4 f1 e2 e2_up w1_f)").
    (The views with people near are left out; the far passers-by of p1_f and s1_19 are blurred.)
02: the game (tools/run_tests.py cristoprado): the front on its square, its doorway, the Paseo, the side door, the
    crossing, the east end on the Calle del Cristo, the bell tower, the calvario, from the air, at night.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'cristoprado')
os.makedirs(OUT, exist_ok=True)
sv = sys.argv[1] if len(sys.argv) > 1 else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()
BLUR = {'p1_f': [(555, 505, 695, 605)], 's1_19': [(445, 465, 505, 580)]}      # (in the 1024 x 640 picture)


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
        im.paste(im.crop(b).filter(ImageFilter.GaussianBlur(10)), b)
    return im


if sv:
    rows = []
    for n, what in (('p1_f', 'la fachada, desde la placita (2013)'), ('s2_13', 'el costado sur, por el Paseo (2013)'),
                    ('s1_19', 'la puerta lateral y el crucero (2019)'), ('s3', 'el crucero y la cabecera (2024)'),
                    ('s4', 'desde la esquina de la fachada (2024)'), ('f1', 'desde la Calle del Cristo, lejos (2024)'),
                    ('e2', 'la cabecera a la Calle del Cristo (2024)'), ('e2_up', 'su ventanal y el crucero (2024)'),
                    ('w1_f', 'la fachada desde el Paseo (2024)')):
        rows.append(('Street View: ' + what, street(n)))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('La fachada, desde la placita', shot('cristoprado_frente')), ('La portada', shot('cristoprado_portada')),
                             ('Por el Paseo del Cristo', shot('cristoprado_paseo')), ('La puerta lateral', shot('cristoprado_puerta')),
                             ('El crucero y la cabecera', shot('cristoprado_crucero')), ('La cabecera, a la Calle del Cristo', shot('cristoprado_cabecera')),
                             ('El campanario', shot('cristoprado_campanario')), ('El calvario, en el parque', shot('cristoprado_calvario')),
                             ('Desde el aire', shot('cristoprado_aire')), ('De noche', shot('cristoprado_frente_noche'))], 800, 450, 2)
