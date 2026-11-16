"""The sheets shown to the user of the corner house of the bank and the copy shop (guion/fotos/bancosancho/).

    python tools/bancosancho/hojas.py [SV_FOLDER]            (the Street View pictures fetched by capturas.py)

01: Street View (2024, and 2019 for the bank) beside the game from the same spots (run first: tools/run_tests.py
    "$(python tools/bancosancho/vistas.py SV_FOLDER d_frente c_frente c_ladrillo f_lejos a_lejos)").
02: the game: morning, afternoon and night, the arrow into the copy shop (tools/run_tests.py bancosancho).
03: the copy shop's inside, and the girl of the Recress in it (the same run, and tools/run_tests.py recress shots).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'bancosancho')
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
    for n, what in (('d_frente', 'el banco, 2024'), ('c_frente', 'la copistería, 2024'), ('c_ladrillo', 'el tramo de ladrillo, 2024'),
                    ('f_lejos', 'la esquina, 2024'), ('a_lejos', 'desde el oeste, 2024')):     # (none with people close: e_esquina and s1_lado have them)
        rows.append(('Street View: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('La esquina, por la mañana', shot('bancosancho_esquina')), ('El banco, abierto', shot('bancosancho_banco')),
                             ('La copistería, abierta', shot('bancosancho_copisteria')), ('El electricista', shot('bancosancho_electricista')),
                             ('A las 15:30: el banco cerrado, la copistería en la siesta', shot('bancosancho_copisteria_tarde')),
                             ('A las 22:00, todo cerrado', shot('bancosancho_esquina_noche')),
                             ('Por San Francisco', shot('bancosancho_sanfrancisco')), ('Desde lo alto', shot('bancosancho_aire'))], 800, 450, 2)
sheet('03_copisteria_dentro.jpg', [('La flecha verde de la puerta de cristal', shot('bancosancho_flecha')), ('Dentro, al entrar', shot('bancosancho_dentro_entrada')),
                                   ('El mostrador', shot('bancosancho_dentro_mostrador')), ('Las copiadoras y el plóter', shot('bancosancho_dentro_copiadoras')),
                                   ('Misión del Recress: a por los carteles', shot('recress_5_copisteria_dentro')), ('La chica de la copistería', shot('recress_5_copisteria'))], 800, 450, 2)
