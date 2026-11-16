"""The sheets shown to the user of the kebab house of the Calle de Santa Ana ("Tele Dürum") (guion/fotos/tele_durum/).

    python tools/teledurum/hojas.py SV_FOLDER        (the Street View pictures fetched by capturas.py)

01: Street View (November 2024) beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/teledurum/vistas.py SV_FOLDER f24 o24 e24 f24_alto)").
02: the game's own pictures (tools/run_tests.py teledurum), shut at midday.
03: its hours (18:00 to 04:00): shut by day, open in the evening and at night, the spit turning.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'tele_durum')
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
    for n, what in (('f24', 'de frente'), ('f24_alto', 'la planta de arriba'), ('o24', 'desde el oeste'), ('e24', 'desde el este')):
        rows.append(('Street View, noviembre de 2024: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('La fachada', shot('teledurum_frente')), ('La entrada y la máquina de bolas', shot('teledurum_entrada')),
                             ('La máquina de bolas', shot('teledurum_maquina')), ('El rótulo', shot('teledurum_rotulo')),
                             ('La planta de arriba', shot('teledurum_alto')), ('Desde el este', shot('teledurum_desde_este'))], 800, 450, 2)
sheet('03_horario.jpg', [('12:30, cerrado: persianas bajadas', shot('teledurum_frente')), ('18:30, abierto: persianas subidas, puertas abiertas, luces', shot('teledurum_abierto_frente')),
                         ('23:00, abierto de noche', shot('teledurum_noche_frente')), ('04:30, cerrado otra vez', shot('teledurum_madrugada_frente')),
                         ('La entrada, de noche', shot('teledurum_noche_entrada')), ('Desde la puerta', shot('teledurum_abierto_dentro')),
                         ('El asador de Kebab Luis, girando', shot('teledurum_abierto_asador')), ('Por la ventana grande', shot('teledurum_abierto_ventana'))], 800, 450, 2)
