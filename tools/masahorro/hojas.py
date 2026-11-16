"""The sheets shown to the user of the MasAhorro (guion/fotos/masahorro/).

    python tools/masahorro/hojas.py [SV_FOLDER]            (the Street View pictures fetched by capturas.py)

01: Street View (November 2024) beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/masahorro/vistas.py SV_FOLDER vc_frente ne_puerta nf_este sb_sur nb_norte na_cargadores)").
02: the game's own pictures (tools/run_tests.py masahorro).
03: the orthophoto beside the game from the air.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'masahorro')
os.makedirs(OUT, exist_ok=True)
sv = sys.argv[1] if len(sys.argv) > 1 else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()
sys.path.insert(0, HERE)


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


def pairs(name, views):
    rows = []
    for n, what in views:
        rows.append(('Street View: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet(name, rows, 800, 500, 2)


def ortho():
    """the orthophoto turned to the shop's frame, as the game's top view is taken"""
    import subprocess
    tmp = os.path.join(OUT, '_marco.jpg')
    subprocess.run([sys.executable, os.path.join(HERE, 'marco.py'), tmp, '-12,-64,42,82', '8'], check=True, capture_output=True)
    im = Image.open(tmp).convert('RGB')
    os.remove(tmp)
    return im


if sv:
    pairs('01_street_view_y_juego.jpg', (('vc_frente', 'el frente, desde la Calle de las Viñas'), ('ne_puerta', 'la entrada'), ('nc_norte', 'el aparcamiento y el frente'),
                                          ('nf_este', 'el lado de la Noria'), ('sb_sur', 'la zona de carga, detrás'), ('na_cargadores', 'los cargadores y la marquesina de los carros')))
sheet('02_en_el_juego.jpg', [('Desde el aire', shot('masahorro_aire')), ('El frente', shot('masahorro_frente')),
                             ('La entrada', shot('masahorro_entrada')), ('Bajo la marquesina', shot('masahorro_marquesina')),
                             ('El aparcamiento', shot('masahorro_aparcamiento')), ('Los carros y los cargadores', shot('masahorro_carros')),
                             ('El lado de la Noria', shot('masahorro_noria')), ('Detrás: la zona de carga', shot('masahorro_carga')),
                             ('La entrada desde la Viñas', shot('masahorro_vinas')), ('A las 20:30, abierto', shot('masahorro_noche')),
                             ('A las 22:30, cerrado', shot('masahorro_cerrado')), ('El cuarto de máquinas, detrás', shot('masahorro_maquinas'))], 800, 450, 2)
sheet('03_ortofoto_y_juego.jpg', [('Ortofoto (PNOA, IGN), girada a la nave', ortho()), ('El juego, desde arriba', shot('masahorro_planta'))], 432, 1168, 2)
