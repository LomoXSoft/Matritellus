"""The sheets shown to the user of the Silo del Tío Anaranjao (guion/fotos/silo/).

    python tools/silo/hojas.py SV_FOLDER P360_FOLDER

01: outside. Street View (November 2024: tools/molino/panos.py foto ... into SV_FOLDER as g1_e, g3_n, g4_n) and the
    orthophoto (tools/ign/silo.jpg) beside the game (tools/run_tests.py silo: silo_porton, silo_esquina, silo_aire...).
02: the way down, the court and the stable; 03: the first house; 04: the second house. For each room, a strip of one of
    the tour's 360 photos (September 2019; P360_FOLDER: tools/silo/baja360.py) over the game: the room as the test
    photographs it and as the player sees it, from above with its lid off.
The 360 photos and Street View's are other people's: NOT kept in the repository (only these sheets, for the user).
"""
import json, os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
SHOTS = os.path.join(ROOT, 'godot', 'shots')
OUT = os.path.join(ROOT, 'guion', 'fotos', 'silo')
os.makedirs(OUT, exist_ok=True)
sv, p360 = sys.argv[1], sys.argv[2]
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()
W = 1600


def fit(im, w, h):
    r = w / h
    if im.size[0] / im.size[1] > r:
        nw = int(im.size[1] * r); im = im.crop(((im.size[0] - nw) // 2, 0, (im.size[0] + nw) // 2, im.size[1]))
    else:
        nh = int(im.size[0] / r); im = im.crop((0, (im.size[1] - nh) // 2, im.size[0], (im.size[1] + nh) // 2))
    return im.resize((w, h), Image.LANCZOS)


def shot(n):
    return Image.open(os.path.join(SHOTS, n + '.png')).convert('RGB')


def strip(n, turn=0.0):
    """a 360 photo's middle band, the whole way round; `turn` slides it (0..1) to put something in the middle"""
    im = Image.open(os.path.join(p360, n + '.jpg')).convert('RGB')
    w, h = im.size
    dx = int(w * turn) % w
    if dx:
        im = Image.composite(im, im, Image.new('L', im.size, 255))
        im = Image.fromarray(__import__('numpy').roll(__import__('numpy').asarray(im), -dx, axis=1))
    return im.crop((0, int(h * 0.27), w, int(h * 0.8)))


def sheet(name, blocks):
    """blocks: [('wide', label, image)] or [('pair', (label, image), (label, image))]"""
    parts = []
    for b in blocks:
        if b[0] == 'wide':
            im = b[2]
            hh = int(im.size[1] * W / im.size[0])
            parts.append((b[1], im.resize((W, hh), Image.LANCZOS), None))
        else:
            parts.append((b[1][0], fit(b[1][1], W // 2 - 3, 450), (b[2][0], fit(b[2][1], W // 2 - 3, 450))))
    total = sum(p[1].size[1] + 26 for p in parts)
    out = Image.new('RGB', (W, total), (22, 22, 24))
    d = ImageDraw.Draw(out)
    y = 0
    for label, im, other in parts:
        d.text((6, y + 4), label, fill=(240, 240, 240), font=font)
        out.paste(im, (0, y + 26))
        if other:
            d.text((W // 2 + 9, y + 4), other[0], fill=(240, 240, 240), font=font)
            out.paste(other[1], (W // 2 + 3, y + 26))
        y += im.size[1] + 26
    path = os.path.join(OUT, name)
    out.save(path, quality=88)
    print(path, out.size)


def street(n):
    return Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')


def ortho():
    j = json.load(open(os.path.join(ROOT, 'tools', 'ign', 'silo.json')))
    im = Image.open(os.path.join(ROOT, 'tools', 'ign', 'silo.jpg')).convert('RGB')
    s = 1.0 / j['mpp']
    box = [int((502 - j['x0']) * s), int((298 - j['z0']) * s), int((536 - j['x0']) * s), int((326 - j['z0']) * s)]
    return im.crop(box)


sheet('01_fuera.jpg', [
    ('pair', ('Street View (2024): el portón, en la calle de San Agustín', street('g1_e')), ('El juego: el portón y su cartel', shot('silo_porton'))),
    ('pair', ('Street View (2024): la tapia por la esquina sur', street('g3_n')), ('El juego: la esquina', shot('silo_esquina'))),
    ('pair', ('La ortofoto: el patio y el caño', ortho()), ('El juego, desde el aire', shot('silo_aire'))),
    ('pair', ('El juego: el portón abierto, con la bajada al fondo', shot('silo_porton_cerca')), ('El juego: la flecha verde en el portón', shot('silo_flecha'))),
    ('pair', ('El juego, desde el norte', shot('silo_aire_norte')), ('El juego, desde la calle de la Paz', shot('silo_calle'))),
    ('pair', ('El juego, de noche', shot('silo_porton_noche')), ('El decorado del interior, desde el aire', shot('silo_set_aire'))),
])
sheet('02_bajada_patio_y_cuadra.jpg', [
    ('wide', 'Foto 360 (2019): la bajada, desde el portón', strip('e30', 0.05)),
    ('pair', ('El juego: la bajada', shot('silo_bajada')), ('El juego: al entrar', shot('silo_jugador_entrada'))),
    ('pair', ('El juego: la escalera, desde el patio', shot('silo_escalera')), ('El juego: bajando', shot('silo_jugador_rampa'))),
    ('wide', 'Foto 360 (2019): el patio, con las puertas', strip('e21')),
    ('pair', ('El juego: el patio', shot('silo_patio')), ('El juego: en el patio', shot('silo_jugador_patio'))),
    ('wide', 'Foto 360 (2019): la cuadra', strip('e16')),
    ('pair', ('El juego: la cuadra', shot('silo_cuadra_b')), ('El juego: en la cuadra', shot('silo_jugador_cuadra'))),
])
sheet('03_primera_casa.jpg', [
    ('wide', 'Foto 360 (2019): el portal de la primera casa', strip('e15')),
    ('pair', ('El juego: el portal', shot('silo_portal')), ('El juego: en el portal', shot('silo_jugador_portal'))),
    ('wide', 'Foto 360 (2019): la cocina', strip('e07')),
    ('pair', ('El juego: la cocina', shot('silo_cocina_mesa')), ('El juego: en la cocina', shot('silo_jugador_cocina'))),
    ('wide', 'Foto 360 (2019): la despensa', strip('e01')),
    ('pair', ('El juego: la despensa', shot('silo_despensa')), ('El juego: en la despensa', shot('silo_jugador_despensa'))),
    ('wide', 'Foto 360 (2019): la alcoba', strip('e06')),
    ('pair', ('El juego: la alcoba', shot('silo_alcoba_b')), ('El juego: en la alcoba', shot('silo_jugador_alcoba'))),
])
sheet('04_segunda_casa.jpg', [
    ('wide', 'Foto 360 (2019): la cocina de la segunda casa', strip('e31')),
    ('pair', ('El juego: la cocina', shot('silo_cocina2')), ('El juego: en la cocina', shot('silo_jugador_cocina2'))),
    ('pair', ('El juego: la cocina, hacia la puerta', shot('silo_cocina2_mesa')), ('El juego: la alcoba amarilla', shot('silo_alcoba2'))),
    ('wide', 'Foto 360 (2019): la alcoba de la cama amarilla', strip('e38')),
    ('pair', ('El juego: en la alcoba amarilla', shot('silo_jugador_alcoba2')), ('El juego: la alcoba azul', shot('silo_alcoba3'))),
    ('wide', 'Foto 360 (2019): la alcoba de la cama azul', strip('e32')),
    ('pair', ('El juego: en la alcoba azul', shot('silo_jugador_alcoba3')), ('El juego: el patio, hacia el portón', shot('silo_patio_atras'))),
])
