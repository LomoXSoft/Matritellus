"""The sheets shown to the user of the supermarket ("Mercamona") and its car park (guion/fotos/mercamona/).

    python tools/mercamona/hojas.py SV_FOLDER        (the Street View pictures fetched by capturas.py)

01: Street View (November 2024) beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/mercamona/vistas.py W3_f W5_f E4_w E2_s)").
02: the game's own pictures (tools/run_tests.py mercamona).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'mercamona')
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
    for n, what in (('W3_f', 'la entrada, desde la carretera antigua'), ('W5_f', 'el muelle de carga'), ('E4_w', 'el aparcamiento y la planta bajo la tienda'), ('E2_s', 'la puerta de coches y la rampa')):
        rows.append(('Street View, noviembre de 2024: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('Desde la carretera antigua', shot('mercamona_carretera')), ('La entrada', shot('mercamona_entrada')),
                             ('La fachada oeste: valla de lamas, césped y chopos', shot('mercamona_oeste')), ('El muelle de carga', shot('mercamona_muelle')),
                             ('El bloque noreste y la casita antigua', shot('mercamona_norte')), ('La puerta de coches: cartel, señal de altura, rampa', shot('mercamona_rampa')),
                             ('El aparcamiento, una planta por debajo', shot('mercamona_aparcamiento')), ('Las plazas bajo la tienda', shot('mercamona_bajo_tienda')),
                             ('Dentro, bajo la tienda', shot('mercamona_dentro')), ('Desde el aire', shot('mercamona_aire'))], 800, 450, 2)
