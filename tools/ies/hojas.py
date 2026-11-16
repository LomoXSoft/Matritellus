"""The sheets shown to the user of the IES Valdeacero (guion/fotos/ies_valdeacero/).

    python tools/ies/hojas.py [SV_FOLDER]            (the Street View pictures fetched by capturas.py)

01: Street View (November 2024) beside the game from the same spots on the avenue (run first:
    tools/run_tests.py "$(python tools/ies/vistas.py SV_FOLDER c_puerta f_gimnasio i_esquina j_pistas)").
02: the game's own pictures (tools/run_tests.py ies).
03: the orthophoto beside the game from the air.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'ies_valdeacero')
IGN = os.path.join(HERE, '..', 'ign')
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


def pairs(name, views):
    rows = []
    for n, what in views:
        rows.append(('Street View: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet(name, rows, 800, 500, 2)


def ortho():
    """the two orthophotos of it put together (north up), over the school's whole ground"""
    a = Image.open(os.path.join(IGN, 'ies_valdeacero.jpg')).convert('RGB')          # x -230..-20, z -1340..-1170, 0.1 m
    b = Image.open(os.path.join(IGN, 'ies_valdeacero_sur.jpg')).convert('RGB')      # x -230..-20, z -1180..-1090
    out = Image.new('RGB', (a.size[0], a.size[1] + b.size[1] - 100))
    out.paste(a, (0, 0))
    out.paste(b, (0, a.size[1] - 100))
    return out.crop((300, 250, 1800, 2150))                                        # x -200..-50, z -1315..-1125


if sv:
    pairs('01_street_view_y_juego.jpg', (('c_puerta', 'la puerta del aparcamiento'), ('f_gimnasio', 'el gimnasio'), ('i_esquina', 'la entrada'), ('j_pistas', 'la entrada y las pistas')))
sheet('02_en_el_juego.jpg', [('Desde el aire', shot('ies_aire')), ('Desde el aire, por el norte', shot('ies_aire_norte')),
                             ('La entrada', shot('ies_entrada')), ('Desde la avenida', shot('ies_avenida')),
                             ('La puerta del aparcamiento', shot('ies_aparcamiento')), ('Las pistas', shot('ies_pistas')),
                             ('El edificio principal y sus patios', shot('ies_peine')), ('El salón y el bloque de FP', shot('ies_norte')),
                             ('El huerto y el invernadero', shot('ies_huerto')), ('El gimnasio desde los árboles', shot('ies_gimnasio'))], 800, 450, 2)
if sv:
    pairs('04_entrada.jpg', (('j_entrada', 'la entrada, de frente'), ('k_entrada', 'la entrada, desde el sur'), ('i_entrada', 'la conserjería, desde el norte')))
sheet('03_ortofoto_y_juego.jpg', [('Ortofoto (PNOA, IGN)', ortho()), ('El juego, desde arriba', shot('ies_planta'))], 760, 960, 2)
