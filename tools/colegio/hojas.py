"""The sheets shown to the user of the old school of the Avenida de Juan Carlos I (guion/fotos/colegio_viejo/).

    python tools/colegio/hojas.py [SV_FOLDER]        (the Street View pictures fetched by capturas.py)

01 and 02: Street View beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/colegio/vistas.py SV_FOLDER je13 jd jb jf pb pd sb sd)").
03: the game's own pictures (tools/run_tests.py colegio).
04: the bus shelter and the floodlights by the fence (the user's two notes on the first version).
05: (the health centre's two signs, made by hand: see referencias/colegio_viejo/LEEME.md.)
06: the name plate of tiles over the door: the user's photograph of the real one beside the game's.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'colegio_viejo')
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
    pairs('01_street_view_y_juego_frente.jpg', (('je13', 'la fachada (marzo de 2013, sin hojas)'), ('jd', 'la fachada (noviembre de 2024)'), ('jb', 'desde la esquina de Peso'), ('jf', 'desde la esquina de Santa Clara')))
    pairs('02_street_view_y_juego_lados.jpg', (('pb', 'la torre oeste, desde Peso'), ('pd', 'calle del Peso'), ('sb', 'la torre este, desde Santa Clara'), ('sd', 'el portón de Santa Clara')))
sheet('03_en_el_juego.jpg', [('La fachada', shot('colegio_frente')), ('De cerca', shot('colegio_frente_cerca')), ('La puerta y el balcón', shot('colegio_puerta')), ('Los arcos de la torre', shot('colegio_arcos')),
                             ('La torre oeste', shot('colegio_torre_oeste')), ('La torre este', shot('colegio_torre_este')), ('Calle del Peso', shot('colegio_peso')), ('Calle de Santa Clara', shot('colegio_santa_clara')),
                             ('La verja de la avenida', shot('colegio_verja')), ('La esquina de Santa Clara', shot('colegio_esquina')), ('La pista', shot('colegio_pista')), ('Desde el aire', shot('colegio_aire'))], 800, 450, 2)
if sv:
    sheet('04_parada_y_focos.jpg', [('Street View, marzo de 2013: la parada', Image.open(os.path.join(sv, 'jd13.jpg')).convert('RGB')), ('El juego: la parada', shot('colegio_parada')),
                                    ('La parada, desde la esquina de Peso', shot('colegio_parada_lado')), ('Los focos, junto a la verja', shot('colegio_focos'))], 800, 500, 2)
real = os.path.join(HERE, '..', '..', 'referencias', 'colegio_viejo', 'placa_original.webp')
if os.path.exists(real):
    sheet('06_placa.jpg', [('Tu foto de la placa real', Image.open(real).convert('RGB')), ('El juego: la placa y el paño de celosía', shot('colegio_placa')),
                           ('La placa pintada para el juego', whole(Image.open(os.path.join(HERE, '..', '..', 'godot', 'assets', 'colegio', 'placa_instituto.png')).convert('RGB'), 800, 357)), ('La puerta', shot('colegio_puerta'))], 800, 357, 2)
