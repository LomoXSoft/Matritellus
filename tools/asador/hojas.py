"""The sheets of the roast chicken shop "Javi" shown to the user (guion/fotos/asador/).

    python tools/asador/hojas.py                       the game's own pictures -> guion/fotos/asador/01, 02
    python tools/asador/hojas.py OUT_FOLDER SV.jpg FOTO.jpg
        the front beside Street View (SV.jpg) and the inside beside the user's picture of the real counter (FOTO.jpg):
        other people's pictures, so OUT_FOLDER is NOT in the repository

The game's pictures: python tools/run_tests.py asador (godot/shots/asador_*.png).
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
    return Image.open(os.path.join(SHOTS, 'asador_' + n + '.png')).convert('RGB')


if len(sys.argv) > 3:
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    sv = Image.open(sys.argv[2]).convert('RGB')
    foto = Image.open(sys.argv[3]).convert('RGB')
    w, h = foto.size
    foto = foto.crop((0, int(h * 0.33), w, int(h * 0.67)))          # (the picture itself, out of the telephone's screen)
    sheet(os.path.join(out, 'comparacion.jpg'), [('Street View 2024 · la fachada', sv), ('El juego · la fachada, abierto', shot('frente_abierto')),
          ('Tu foto · el mostrador desde dentro', foto), ('El juego · desde detrás del mostrador', shot('dentro_foto'))], 800, 500, 2)
else:
    out = os.path.join(ROOT, 'guion', 'fotos', 'asador')
    os.makedirs(out, exist_ok=True)
    sheet(os.path.join(out, '01_fachada.jpg'), [('Abierto (un martes a mediodía), de frente', shot('frente_abierto')), ('La tienda, abierta', shot('tienda_abierto')),
          ('Cerrado (un miércoles): la reja echada', shot('frente_cerrado')), ('La tienda, cerrada', shot('tienda_cerrado')),
          ('La calle de los Arcos desde el sur', shot('calle_abierto')), ('Desde el norte', shot('calle_norte_abierto')),
          ('De noche, cerrado', shot('frente_noche_cerrado')), ('La tienda de noche', shot('tienda_noche_cerrado'))], 800, 450, 2)
    sheet(os.path.join(out, '02_interior.jpg'), [('Al entrar', shot('dentro_puerta')), ('El mostrador', shot('dentro_mostrador')),
          ('Las bandejas', shot('dentro_bandejas')), ('Desde detrás del mostrador (como tu foto)', shot('dentro_foto')),
          ('El asador', shot('dentro_asador')), ('La carta', shot('dentro_carta')),
          ('El rincón del azafrán', shot('dentro_rincon')), ('Desde la izquierda de la puerta', shot('dentro_izquierda'))], 800, 450, 2)
