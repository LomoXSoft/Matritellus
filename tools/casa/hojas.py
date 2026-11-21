"""The sheets shown to the user of the house you inherit, Calle de Alemania 5, in its six states (guion/fotos/casa/).

    python tools/casa/hojas.py

01: the six fronts from the street (tools/run_tests.py casa: godot/shots/casa_N_frente.png and casa_N_lado.png).
02: the inside in its six states (the same run: godot/shots/casa_dentro_N_*.png).
03: the plants of the last front, asked for by the user (casa_5_frente.png and casa_5_plantas.png).
"""
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
SHOTS = os.path.join(ROOT, 'godot', 'shots')
OUT = os.path.join(ROOT, 'guion', 'fotos', 'casa')
os.makedirs(OUT, exist_ok=True)
try:
    font = ImageFont.truetype('arial.ttf', 18)
except Exception:
    font = ImageFont.load_default()
NAMES = ['0 · heredada, hecha un asco', '1 · arreglada', '2 · primera ampliación', '3 · habitación a la izquierda',
         '4 · habitación a la derecha', '5 · segunda planta']


def sheet(name, rows, w, h, cols):
    n = (len(rows) + cols - 1) // cols
    out = Image.new('RGB', (cols * w + (cols - 1) * 6, n * (h + 28)), (22, 22, 24))
    d = ImageDraw.Draw(out)
    for i, (label, im) in enumerate(rows):
        x, y = (i % cols) * (w + 6), (i // cols) * (h + 28)
        d.text((x + 6, y + 4), label, fill=(240, 240, 240), font=font)
        out.paste(im.resize((w, h), Image.LANCZOS), (x, y + 28))
    path = os.path.join(OUT, name)
    out.save(path, quality=90)
    print(path, out.size)


def shot(n):
    return Image.open(os.path.join(SHOTS, n + '.png')).convert('RGB')


rows = []
for i, nm in enumerate(NAMES):
    rows.append((nm + ' (de frente)', shot('casa_%d_frente' % i)))
    rows.append((nm + ' (desde la calle)', shot('casa_%d_lado' % i)))
rows.append(('5 · sus plantas, desde el otro extremo', shot('casa_5_plantas')))
rows.append(('5 · de noche, con los faroles', shot('casa_5_noche')))
sheet('01_fachadas.jpg', rows, 800, 450, 2)
rows = [('0 · heredada: la sala', shot('casa_dentro_0_sala')), ('1 · arreglada: la sala', shot('casa_dentro_1_sala')),
        ('2 · primera ampliación: la sala, más grande', shot('casa_dentro_2_sala')), ('2 · la cocina y el comedor', shot('casa_dentro_2_cocina')),
        ('3 · habitación a la izquierda: el baño', shot('casa_dentro_3_bano')), ('4 · habitación a la derecha: el salón', shot('casa_dentro_4_salon')),
        ('5 · segunda planta: la sala, con la puerta de detrás', shot('casa_dentro_5_cocina')), ('5 · la escalera tras esa puerta', shot('casa_dentro_5_escalera')),
        ('5 · la planta de arriba', shot('casa_dentro_5_arriba'))]
sheet('02_interiores.jpg', rows, 800, 450, 2)
rows = [('5 · segunda planta, con sus plantas (de frente)', shot('casa_5_frente')), ('5 · desde el otro extremo', shot('casa_5_plantas'))]
sheet('03_plantas.jpg', rows, 1000, 562, 1)
