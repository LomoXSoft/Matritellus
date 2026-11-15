"""The sheets shown to the user of the convent of Santa Ana (guion/fotos/convento_santa_ana/).

    python tools/santaana/hojas.py SV_FOLDER        (the Street View pictures fetched by capturas.py)

01: Street View (November 2024) beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/santaana/vistas.py M5_f M6_f M7_sw M5_sw)").
02: the game's own pictures (tools/run_tests.py santaana).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'convento_santa_ana')
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
    for n, what in (('M5_f', 'la puerta grande y sus ventanas'), ('M6_f', 'el final de la fachada y la portada de la iglesia'), ('M7_sw', 'el compás, desde el norte'), ('M5_sw', 'la puerta pequeña y la torre')):
        rows.append(('Street View, noviembre de 2024: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('La calle de las Monjas, empedrada y con tráfico', shot('santaana_calle')), ('La fachada, mitad sur, y la torre', shot('santaana_frente_sur')),
                             ('La puerta grande', shot('santaana_puerta')), ('La fachada, mitad norte', shot('santaana_frente_norte')),
                             ('La torre', shot('santaana_torre')), ('El compás y la portada de la iglesia', shot('santaana_compas')),
                             ('El fraile de bronce, en su pedestal', shot('santaana_fraile')), ('La cabecera de la iglesia', shot('santaana_iglesia')),
                             ('Desde el cruce con Santiago Apóstol', shot('santaana_desde_norte')), ('El costado de Santiago Apóstol', shot('santaana_santiago')),
                             ('El empedrado: adoquín en el centro, ladrillo a los lados', shot('santaana_suelo')), ('Desde el aire', shot('santaana_aire'))], 800, 450, 2)
