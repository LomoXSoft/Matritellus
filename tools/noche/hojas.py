"""The sheets shown to the user of the Noche (guion/fotos/noche/).

    python tools/noche/hojas.py [SV_FOLDER]            (the Street View pictures fetched by capturas.py)

01: Street View (2013 and 2019 for the shop as it was, 2024 for the house) beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/noche/vistas.py SV_FOLDER d19_frente d13_frente c_frente e_frente d_balcones)").
02: the game: open, shut, at night, walking in by its arrow (tools/run_tests.py noche).
03: its inside (the same run).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'noche')
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
    for n, what in (('d19_frente', 'de frente, 2019 (el diseño de antes)'), ('d13_frente', 'de frente, 2013'), ('c_frente', 'desde el oeste, 2024'),
                    ('e_frente', 'desde el este, 2024'), ('d_balcones', 'los balcones, 2024')):
        rows.append(('Street View: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('De frente, abierta (mediodía)', shot('noche_frente')), ('La tienda, abierta', shot('noche_tienda')),
                             ('A las 22:30, cerrada', shot('noche_frente_cerrado')), ('Cerrada: la persiana bajada', shot('noche_tienda_cerrado')),
                             ('A las 20:30, abierta: el rótulo encendido', shot('noche_tienda_noche')), ('Desde el oeste', shot('noche_oeste')),
                             ('La flecha verde de la puerta', shot('noche_flecha')), ('Dentro, al entrar', shot('noche_dentro_jugador'))], 800, 450, 2)
sheet('03_interior.jpg', [('La entrada', shot('noche_dentro_entrada')), ('Desde lo alto, junto a la puerta', shot('noche_dentro_alto')),
                          ('Un pasillo', shot('noche_dentro_pasillo')), ('La caja', shot('noche_dentro_caja')),
                          ('El fondo: lácteos y el logo', shot('noche_dentro_fondo')), ('Los balcones', shot('noche_balcones'))], 800, 450, 2)
