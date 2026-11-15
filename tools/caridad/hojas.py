"""The sheets shown to the user of the hermitage of the Caridad's island (guion/fotos/ermita_caridad/).

    python tools/caridad/hojas.py SV_FOLDER [ROLLO_FOLDER]     (Street View pictures: a_n.jpg, e24_este.jpg, g13_sur.jpg, f13_fuente.jpg ...)

01: Street View beside the game.   02: the game's own pictures (`tools/run_tests.py caridad --window`).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'ermita_caridad')
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
    return Image.open(os.path.join(SHOTS, 'caridad_' + n + '.png')).convert('RGB')


if sv:
    rows = []
    for n, g, what in (('e24_este', 'cruz', 'noviembre de 2024: la ermita, el crucero y el cuerpo de la esquina'), ('a_n', 'avenida', 'noviembre de 2024: el muro y la verja desde la avenida'),
                       ('g13_sur', 'guarderia', 'marzo de 2013: la guardería y su patio'), ('f13_fuente', 'fuente', 'marzo de 2013: el parque de la fuente')):
        rows.append(('Street View, ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego', shot(g)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('Desde la avenida', shot('avenida')), ('La fachada de poniente, con sus columnas', shot('poniente')), ('Las columnas y la casa baja', shot('columnas')), ('La fuente', shot('fuente')),
                             ('Las columnas, desde la calle del Rollo', shot('rollo_columnas')), ('El lado de la plaza', shot('ermita')), ('El paseo de baldosa, el césped y el crucero', shot('paseo')), ('La guardería y su patio', shot('guarderia')), ('El patio, con sus juegos, la portería y los balones', shot('patio')),
                             ('Desde el aire', shot('aire'))], 800, 450, 2)
sheet('04_patio_guarderia.jpg', [('El patio de la guardería, desde la esquina del Peso', shot('patio')), ('Desde la plaza', shot('guarderia'))], 800, 450, 2)
# 03: the Calle del Rollo -- Street View of November 2024 from three spots of it (ROLLO_FOLDER: x-06.jpg, x+13.jpg, x+41.jpg,
# fetched from the panoramas AJc5A8sLTP699Y9K1nEfOA's neighbours looking south) beside the game
rollo = sys.argv[2] if len(sys.argv) > 2 else ''
if rollo:
    rows = []
    for n, g, what in (('x-06', 'rollo_columnas', 'la fachada de poniente y las columnas'), ('x+13', 'rollo_casa', 'la casa baja, blanca sobre zócalo salmón'),
                       ('x+41', 'rollo', 'la entrada de la escuela infantil')):
        rows.append(('Street View desde la calle del Rollo, noviembre de 2024: ' + what, Image.open(os.path.join(rollo, n + '.jpg')).convert('RGB')))
        rows.append(('El juego', shot(g)))
    rows.append(('El juego: la fachada de poniente, de frente', shot('poniente')))
    rows.append(('El juego: las columnas y la puerta grande', shot('columnas')))
    sheet('03_calle_del_rollo_y_poniente.jpg', rows, 800, 500, 2)
