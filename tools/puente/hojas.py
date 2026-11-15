"""The sheets shown to the user of the old bridge of the Arroyuelo Medio (guion/fotos/puente/).

    python tools/puente/hojas.py SV_FOLDER        (the Street View pictures fetched by capturas.py)

01: Street View of May 2009 beside the game from the same spots (run first: tools/run_tests.py with
    vistas_sv.py S_se_cerca J_350 J_345 and puente-limpio), and a frame of the film of 1984 beside the game.
02: with the demolition works.   03: clean.   (those two from `tools/run_tests.py puente --window`)
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
REF = os.path.join(HERE, '..', '..', 'referencias', 'puente_arroyuelo')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'puente')
os.makedirs(OUT, exist_ok=True)
sv = sys.argv[1] if len(sys.argv) > 1 else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()


def fit(im, w, h):
    """cropped about its middle to w:h, then that size"""
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
    for n, what in (('S_se_cerca', 'desde la calle del Santo'), ('J_350', 'desde el cruce con Matías Pérez'), ('J_345', 'el extremo de la casa de ladrillo, de cerca')):
        rows.append(('Street View, mayo de 2009: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_pu_' + n)))
    film = Image.open(os.path.join(REF, 'foto_1.jpg')).convert('RGB')
    rows.append(('Película de 1984 (José-María Moreno García)', film.crop((0, 0, 1100, film.size[1]))))
    rows.append(('El juego: el puente desde el cauce', shot('puente_limpio_cauce')))
    sheet('01_street_view_2009_y_juego.jpg', rows, 800, 500, 2)
sheet('02_con_la_obra.jpg', [('Con la obra: desde la calle del Santo', shot('puente_obra_santo')), ('El cauce desde el aire: valla, máquinas, manifestación', shot('puente_obra_aire_norte')),
                             ('Desde la acera, con la manifestación', shot('puente_obra_acera')), ('Bajo el puente: la excavadora, vallada', shot('puente_obra_sur')),
                             ('Desde Matías Pérez: la esquina y el puente', shot('puente_obra_placeta')), ('Desde el aire', shot('puente_obra_aire'))], 800, 450, 2)
sheet('03_limpio.jpg', [('Limpio: desde la calle del Santo', shot('puente_limpio_santo')), ('Desde el cauce', shot('puente_limpio_cauce')),
                        ('Desde el cruce', shot('puente_limpio_sur')), ('La cochera de la casa de ladrillo, a pie de calle', shot('puente_limpio_cochera')),
                        ('Encima del puente', shot('puente_limpio_encima')), ('Desde Matías Pérez', shot('puente_limpio_placeta'))], 800, 450, 2)
