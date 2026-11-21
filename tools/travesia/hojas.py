"""The sheets of the Travesía del Clavel shown to the user (guion/fotos/travesia_clavel/).

    python tools/travesia/hojas.py                     the game's own pictures -> guion/fotos/travesia_clavel/01, 02, 03
    python tools/travesia/hojas.py OUT_FOLDER          the game beside the user's two pictures and Street View's
        (referencias/travesia_clavel/): other people's pictures, so OUT_FOLDER is NOT in the repository

The game's pictures: python tools/run_tests.py travesia (godot/shots/travesia_*.png).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
SHOTS = os.path.join(ROOT, 'godot', 'shots')
REAL = os.path.join(ROOT, 'referencias', 'travesia_clavel')
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
    return Image.open(os.path.join(SHOTS, 'travesia_' + n + '.png')).convert('RGB')


def real(n, top=0.0, bottom=1.0):
    im = Image.open(os.path.join(REAL, n)).convert('RGB')
    return im.crop((0, int(im.size[1] * top), im.size[0], int(im.size[1] * bottom)))


if len(sys.argv) > 1:
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    sheet(os.path.join(out, 'comparacion.jpg'), [
        ('Tu foto · la escalera del Clavel', real('usuario_escalera_clavel.jpg', 0.07, 0.80)), ('El juego · la escalera del Clavel', shot('escalera_dia')),
        ('Street View 2024 · desde el Clavel', real('sv2024_desde_clavel.jpg')), ('El juego · desde el Clavel', shot('clavel_dia')),
        ('Tu foto · las rampas de San Rafael', real('usuario_rampa_san_rafael.jpg', 0.07, 0.80)), ('El juego · las rampas, desde San Rafael', shot('rafael_dia')),
        ('Street View 2024 · desde San Rafael', real('sv2024_desde_san_rafael.jpg')), ('El juego · las rampas, de lado', shot('rampas_dia')),
        ('Street View 2024 · la esquina de San Rafael', real('sv2024_esquina_san_rafael.jpg')), ('El juego · la esquina de la hilera oeste', shot('esquina_rafael_dia')),
    ], 800, 560, 2)
else:
    out = os.path.join(ROOT, 'guion', 'fotos', 'travesia_clavel')
    os.makedirs(out, exist_ok=True)
    sheet(os.path.join(out, '01_san_rafael.jpg'), [
        ('Desde la calle de San Rafael: las tres rampas', shot('rafael_dia')), ('Las rampas, de lado', shot('rampas_dia')),
        ('Desde arriba, donde acaban', shot('rampa_arriba_dia')), ('La esquina de la hilera oeste, con la placa', shot('esquina_rafael_dia')),
    ], 800, 450, 2)
    sheet(os.path.join(out, '02_paseo.jpg'), [
        ('El paseo, hacia el Clavel', shot('paseo_norte_dia')), ('El paseo, hacia San Rafael', shot('paseo_sur_dia')),
        ('Un par de puertas de la hilera este, con su rellano', shot('puertas_dia')), ('La hilera oeste', shot('oeste_dia')),
        ('Desde el aire', shot('aire_dia')), ('De noche', shot('paseo_norte_noche')),
    ], 800, 450, 2)
    sheet(os.path.join(out, '03_clavel.jpg'), [
        ('Desde la calle del Clavel', shot('clavel_dia')), ('La escalera a cuadros', shot('escalera_dia')),
        ('El carril del garaje, bajo el paseo', shot('carril_dia')), ('Desde lo alto de la escalera', shot('arriba_clavel_dia')),
        ('La casa blanca de la esquina', shot('casa_blanca_dia')), ('Desde el aire, por el Clavel', shot('aire_norte_dia')),
    ], 800, 450, 2)
