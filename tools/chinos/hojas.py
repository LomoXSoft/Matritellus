"""The sheets shown to the user of the grocer's at the point between San José and Santo Domingo (guion/fotos/chinos_arroyuelo/).

    python tools/chinos/hojas.py [SV_FOLDER]        (the Street View pictures fetched by capturas.py)

01 and 02: Street View (November 2024) beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/chinos/vistas.py SV_FOLDER e24 e24_zoom ne24_punta se24_punta n24 nb24 cal_n_e s24 cal_s_o cal_s_e1)").
03: the game's own pictures (tools/run_tests.py chinos).
04: its hours (7 to 21 from Monday to Friday, 6 to 2 on Saturdays and Sundays): shut and open.
05: the poster on its door: the user's picture, as tools/chinos/poster.py redrew it, and where it hangs.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'chinos_arroyuelo')
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
    return Image.open(os.path.join(SHOTS, n + '.png')).convert('RGB')


def pairs(name, views):
    rows = []
    for n, what in views:
        rows.append(('Street View, noviembre de 2024: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet(name, rows, 800, 500, 2)


if sv:
    pairs('01_street_view_y_juego_punta.jpg', (('e24', 'la punta'), ('e24_zoom', 'la tienda'), ('ne24_punta', 'la punta desde San José'), ('se24_punta', 'la punta desde Santo Domingo')))
    pairs('02_street_view_y_juego_lados.jpg', (('n24', 'San José, de frente'), ('nb24', 'San José, las verjas'), ('cal_n_e', 'San José, desde la punta'),
                                               ('s24', 'Santo Domingo, de frente'), ('cal_s_o', 'Santo Domingo, desde el oeste'), ('cal_s_e1', 'Santo Domingo, desde la punta')))
sheet('03_en_el_juego.jpg', [('La punta', shot('chinos_punta')), ('La tienda', shot('chinos_tienda')), ('El rótulo', shot('chinos_rotulo')), ('El balcón', shot('chinos_balcon')),
                             ('Calle de San José', shot('chinos_norte')), ('San José desde la punta', shot('chinos_norte_desde_punta')), ('Las verjas de tijera', shot('chinos_norte_verjas')),
                             ('Calle de Santo Domingo', shot('chinos_sur')), ('Santo Domingo desde la punta', shot('chinos_sur_desde_punta')), ('Santo Domingo desde el oeste', shot('chinos_sur_desde_oeste')),
                             ('La puerta de la casa', shot('chinos_puerta')), ('Desde el aire', shot('chinos_aire'))], 800, 450, 2)
sheet('04_horario.jpg', [('Lunes, 12:30: abierta', shot('chinos_tienda')), ('Lunes, 6:40: cerrada (abre a las 7)', shot('chinos_lunes_cerrado_tienda')),
                         ('Cerrada, de cerca: la persiana con sus dos carteles', shot('chinos_lunes_cerrado_cerca')), ('Lunes, 22:00: cerrada (cerró a las 21)', shot('chinos_lunes_noche_cerrado_tienda')),
                         ('Sábado, 23:00: abierta (hasta las 2)', shot('chinos_sabado_noche_abierto')), ('Domingo, 1:00: sigue abierta desde el sábado', shot('chinos_domingo_madrugada_abierto_tienda'))], 800, 450, 2)
ROOT = os.path.join(HERE, '..', '..')
sheet('05_cartel.jpg', [('Tu cartel', Image.open(os.path.join(ROOT, 'referencias', 'chinos_arroyuelo', 'roster_energy_original.png')).convert('RGB')),
                        ('Pasado al estilo del juego', Image.open(os.path.join(ROOT, 'godot', 'assets', 'chinos', 'poster_roster.png')).convert('RGB').resize((942, 1242), Image.NEAREST)),
                        ('En la puerta', shot('chinos_cartel')), ('La tienda', shot('chinos_tienda'))], 800, 600, 2)
