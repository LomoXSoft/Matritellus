"""The sheets shown to the user of the Tricornios' barracks of the Avenida de la Constitución (guion/fotos/cuartel_tricornios/).

    python tools/cuartel/hojas.py [SV_FOLDER]        (the Street View pictures fetched by capturas.py)

01 and 02: Street View (November 2024) beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/cuartel/vistas.py SV_FOLDER ac ab sv_centro aa vb vc vd na)").
03: the game's own pictures (tools/run_tests.py cuartel).
04: the Tricornios' badge and their car's marks (run first: tools/run_tests.py "$(python tools/cuartel/vistas.py coche)").
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'cuartel_tricornios')
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


def whole(im, w, h):
    """the whole picture on a dark ground of that shape (fit() would cut a long one)"""
    r = min(w * 0.92 / im.size[0], h * 0.92 / im.size[1])
    im = im.resize((int(im.size[0] * r), int(im.size[1] * r)), Image.LANCZOS)
    out = Image.new('RGB', (w, h), (40, 40, 44))
    out.paste(im, ((w - im.size[0]) // 2, (h - im.size[1]) // 2))
    return out


def shot(n):
    return Image.open(os.path.join(SHOTS, n + '.png')).convert('RGB')


def pairs(name, views):
    rows = []
    for n, what in views:
        rows.append(('Street View: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet(name, rows, 800, 500, 2)


if sv:
    pairs('01_street_view_y_juego_avenida.jpg', (('ac', 'la fachada de la avenida'), ('sv_centro', 'la entrada'), ('ab', 'desde el norte'), ('aa', 'la esquina con Víctor Pradera')))
    pairs('02_street_view_y_juego_lados.jpg', (('vb', 'Víctor Pradera, el bloque de la esquina'), ('vc', 'la verja del patio'), ('vd', 'Víctor Pradera, el bloque largo'), ('na', 'el patio, desde la calle Nueva')))
sheet('03_en_el_juego.jpg', [('La fachada de la avenida', shot('cuartel_frente')), ('La entrada', shot('cuartel_entrada')), ('La puerta', shot('cuartel_puerta')), ('Los rótulos', shot('cuartel_rotulos')),
                             ('Desde el norte', shot('cuartel_desde_norte')), ('Desde el sur', shot('cuartel_desde_sur')), ('La esquina', shot('cuartel_esquina')), ('Calle de Víctor Pradera', shot('cuartel_norte')),
                             ('La verja del patio', shot('cuartel_verja')), ('El patio, desde la calle Nueva', shot('cuartel_patio_sur')), ('Desde el aire', shot('cuartel_aire')), ('Desde el aire, por detrás', shot('cuartel_aire_patio'))], 800, 450, 2)
if os.path.exists(os.path.join(SHOTS, 'vista_coche_lado.png')):
    logo = Image.open(os.path.join(HERE, '..', '..', 'godot', 'assets', 'tricornios', 'logo.png')).convert('RGBA')
    card = Image.new('RGB', (800, 450), (47, 74, 60))
    small = logo.resize((360, 360), Image.LANCZOS)
    card.paste(small, (220, 45), small)
    sheet('04_logo_y_coche.jpg', [('El logo de los Tricornios', card), ('En la placa de la fachada', shot('cuartel_rotulos')), ('El coche, de lado (hacia la avenida)', shot('vista_coche_lado')), ('El otro lado', shot('vista_coche_fachada')),
                                  ('El capó, desde arriba', shot('vista_coche_alto')), ('De frente', shot('vista_coche_frente'))], 800, 450, 2)
