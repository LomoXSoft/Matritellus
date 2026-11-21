"""The sheets of the almazara "González de la Ruz" shown to the user.

    python tools/almazara/hojas.py                      the game's own pictures -> guion/fotos/almazara/01..03
    python tools/almazara/hojas.py SV_FOLDER OUT_FOLDER  Street View beside the game from the same spot -> OUT_FOLDER
                                                        (Google's pictures: OUT_FOLDER is NOT in the repository)

The game's pictures: python tools/run_tests.py almazara (godot/shots/almazara_*.png); the ones from Street View's
spots: python tools/run_tests.py "$(python tools/almazara/vistas.py SV_FOLDER name ...)" (godot/shots/vista_sv_*.png).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
SHOTS = os.path.join(ROOT, 'godot', 'shots')
try:
    font = ImageFont.truetype('arial.ttf', 18)
except Exception:
    font = ImageFont.load_default()


def sheet(path, rows, w, h, cols):
    n = (len(rows) + cols - 1) // cols
    out = Image.new('RGB', (cols * w + (cols - 1) * 6, n * (h + 28)), (22, 22, 24))
    d = ImageDraw.Draw(out)
    for i, (label, im) in enumerate(rows):
        x, y = (i % cols) * (w + 6), (i // cols) * (h + 28)
        d.text((x + 6, y + 4), label, fill=(240, 240, 240), font=font)
        out.paste(im.resize((w, h), Image.LANCZOS), (x, y + 28))
    out.save(path, quality=88)
    print(path, out.size)


def shot(n):
    return Image.open(os.path.join(SHOTS, n + '.png')).convert('RGB')


def game_like_sv(n):
    """the game's picture from a Street View spot, cut to that picture's shape (16:10)"""
    im = shot('vista_sv_' + n)
    w = int(im.size[1] * 1.6)
    x = (im.size[0] - w) // 2
    return im.crop((x, 0, x + w, im.size[1]))


if len(sys.argv) > 2:
    sv, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    pairs = {
        'comparacion_carretera.jpg': [('c06_mural', 'el mural'), ('c07_patio', 'la entrada'), ('c08_tienda', 'el lado de la tienda'), ('c07_fondo', 'el fondo del patio'),
                                      ('c09', 'el muro y el cobertizo'), ('c12', 'el muro y los depósitos'), ('c18', 'la nave alta'), ('c25_largo', 'la nave alta desde el noreste')],
        'comparacion_triunfo.jpg': [('t02', 'el final de la nave vieja'), ('t03', 'el bloque de dos plantas'), ('t05', 'el tramo viejo'), ('t07', 'las naves'), ('t08', 'las naves'),
                                    ('t12_largo', 'la calle hacia el suroeste')],
    }
    for name, lst in pairs.items():
        rows = []
        for n, label in lst:
            rows.append(('Street View 2024 · ' + label, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
            rows.append(('El juego · ' + label, game_like_sv(n)))
        sheet(os.path.join(out, name), rows, 720, 450, 2)
else:
    out = os.path.join(ROOT, 'guion', 'fotos', 'almazara')
    os.makedirs(out, exist_ok=True)
    sheet(os.path.join(out, '01_carretera.jpg'), [('Llegando por la carretera, tras el taller', shot('almazara_llegada')), ('El mural de la nave vieja', shot('almazara_mural')),
          ('La entrada', shot('almazara_entrada')), ('El muro largo, el cobertizo y los depósitos', shot('almazara_muro')),
          ('El muro hacia la nave alta', shot('almazara_muro_largo')), ('La nave alta', shot('almazara_nave_alta')),
          ('La nave alta desde el noreste', shot('almazara_nave_alta_lejos')), ('Desde el aire', shot('almazara_aire'))], 800, 450, 2)
    sheet(os.path.join(out, '02_patio.jpg'), [('El patio: oficinas y nave de recepción', shot('almazara_patio')), ('El lado de la tienda', shot('almazara_tienda')),
          ('La nave de recepción', shot('almazara_recepcion')), ('Tras el muro: cobertizo y depósitos', shot('almazara_tras_muro')),
          ('El rincón del azafrán escondido', shot('almazara_azafran')), ('El patio de noche', shot('almazara_patio_noche')),
          ('El mural de noche', shot('almazara_mural_noche')), ('La nave alta de noche', shot('almazara_nave_alta_lejos_noche'))], 800, 450, 2)
    sheet(os.path.join(out, '03_triunfo.jpg'), [('La calle del Triunfo desde el suroeste', shot('almazara_triunfo_sw')), ('El bloque de dos plantas', shot('almazara_triunfo_bloque')),
          ('Las naves', shot('almazara_triunfo_naves')), ('Desde el noreste', shot('almazara_triunfo_ne')),
          ('Desde el aire, por el Triunfo', shot('almazara_aire_triunfo'))], 800, 450, 2)
