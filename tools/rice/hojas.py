"""The sheets of the Cafetería Rize and its alley shown to the user (guion/fotos/rice/).

    python tools/rice/hojas.py                         the game's own pictures -> guion/fotos/rice/01, 02
    python -I tools/rice/hojas.py OUT_FOLDER PANO.jpg CENTRE
        the game beside flat views cut out of the 360 photo taken in the alley (vistas360.py; CENTRE: the heading of
        the middle of the photo, 307 for this one): somebody else's photo, so OUT_FOLDER is NOT in the repository

The game's pictures: python tools/run_tests.py rize (godot/shots/rize_*.png).
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
        k = min(w / im.size[0], h / im.size[1])
        t = im.resize((int(im.size[0] * k), int(im.size[1] * k)), Image.LANCZOS)
        out.paste(t, (x + (w - t.size[0]) // 2, y + 28 + (h - t.size[1]) // 2))
    out.save(path, quality=88)
    print(path, out.size)


def shot(n):
    return Image.open(os.path.join(SHOTS, 'rize_' + n + '.png')).convert('RGB')


if len(sys.argv) > 3:
    sys.path.insert(0, HERE)                    # (vistas360.py, beside this: -I leaves the script's folder out)
    import numpy as np
    from vistas360 import view
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    pano = np.asarray(Image.open(sys.argv[2]).convert('RGB'))
    centre = float(sys.argv[3])
    sheet(os.path.join(out, 'comparacion.jpg'), [
        ('Foto 360° (2020) · la cafetería', view(pano, centre, 105, 12, 95)), ('El juego · la cafetería, abierta', shot('cafe_abierto')),
        ('Foto 360° · la casa gris', view(pano, centre, 212, 12, 80)), ('El juego · la casa gris', shot('casa_gris_abierto')),
        ('Foto 360° · el garaje del emblema y el portón verde', view(pano, centre, 300, 8, 95)), ('El juego · el garaje y el portón', shot('garaje_abierto')),
        ('Foto 360° · el rincón de las cajas', view(pano, centre, 20, -10, 80)), ('El juego · el rincón (con el azafrán)', shot('rincon_abierto')),
        ('Foto 360° · hacia la avenida', view(pano, centre, 180, -5, 70)), ('El juego · hacia la avenida', shot('salida_abierto')),
    ], 800, 500, 2)
else:
    out = os.path.join(ROOT, 'guion', 'fotos', 'rice')
    os.makedirs(out, exist_ok=True)
    sheet(os.path.join(out, '01_callejon.jpg'), [
        ('Desde la avenida de Juan Carlos I, abierto: la pizarra en la boca', shot('avenida_abierto')), ('La boca del callejón, cerrado', shot('boca_cerrado')),
        ('Callejón adentro: el portón verde al fondo', shot('fondo_abierto')), ('Mirando hacia la avenida', shot('salida_abierto')),
        ('Desde el aire', shot('aire_abierto')), ('De noche', shot('fondo_noche')),
    ], 800, 450, 2)
    sheet(os.path.join(out, '02_cafeteria.jpg'), [
        ('La cafetería, abierta: terraza y toldo', shot('cafe_abierto')), ('La puerta, abierta', shot('puerta_abierto')),
        ('Cerrada: toldo recogido y puerta echada', shot('puerta_cerrado')), ('De noche', shot('puerta_noche')),
        ('Enfrente: la casa gris y el garaje del emblema', shot('casa_gris_abierto')), ('El garaje, la puerta pintada y el portón verde', shot('garaje_abierto')),
        ('El rincón: cajas, sillas apiladas y el azafrán', shot('rincon_abierto')), ('El fondo, cerrado', shot('fondo_cerrado')),
    ], 800, 450, 2)
