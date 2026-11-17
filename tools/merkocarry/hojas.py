"""The sheets shown to the user of the Merkocarry (guion/fotos/merkocarry/).

    python tools/merkocarry/hojas.py [SV_FOLDER]            (the Street View pictures fetched by capturas.py)

01: Street View (November 2024) beside the game from the same spots, along its four streets (run first:
    tools/run_tests.py "$(python tools/merkocarry/vistas.py SV_FOLDER sa2_alto:-0.78,1.45 cr0_lejos cr3 su0_lejos su5 ma2 ma4 su7_lejos)").
02: the game: its streets, its gates, its car park (tools/run_tests.py merkocarry).
03: at night, shut; from the air.
Views with people near the camera (faces) are left out.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'merkocarry')
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


if sv:
    rows = []
    for n, what in (('sa2_alto', 'Santa Ana, de frente'), ('cr0_lejos', 'el Cristo, desde la Mayordomía'),
                    ('cr3', 'el Cristo: la entrada del parking'), ('su0_lejos', 'el Suspiro, desde el norte'), ('su5', 'el Suspiro: la entrada de clientes'),
                    ('ma2', 'Magallanes: el muro y los porches'), ('ma4', 'la esquina de Magallanes con el Suspiro'), ('su7_lejos', 'el Suspiro, desde el sur')):
        rows.append(('Street View 2024: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
    rows = []                                                  # the Mayordomía's nave beside it (vistas: my_frente my_norte my_sur my_sur2)
    for n, what in (('my_frente', 'la nave de la Mayordomía, de frente'), ('my_sur', 'desde el sur, junto al Merkocarry'), ('my_sur2', 'desde más al sur'),
                    ('my_norte', 'desde la esquina de Santa Ana')):
        if os.path.exists(os.path.join(SHOTS, 'vista_sv_' + n + '.png')):
            rows.append(('Street View 2024: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
            rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    if rows:
        sheet('05_mayordomia.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('Santa Ana', shot('merkocarry_santaana')), ('Santa Ana, desde el oeste', shot('merkocarry_santaana_oeste')),
                             ('El Cristo, desde la Mayordomía', shot('merkocarry_cristo')), ('La entrada del parking', shot('merkocarry_cristo_puerta')),
                             ('El Suspiro', shot('merkocarry_suspiro')), ('La entrada de clientes', shot('merkocarry_suspiro_puerta')),
                             ('Magallanes', shot('merkocarry_magallanes')), ('El aparcamiento', shot('merkocarry_aparcamiento')),
                             ('El aparcamiento, hacia Magallanes', shot('merkocarry_aparcamiento_norte')), ('La puerta trasera', shot('merkocarry_puerta_trasera'))], 800, 450, 2)
sheet('04_interior_y_posters.jpg', [('Santa Ana: la flecha y el póster de Roster', shot('merkocarry_flecha_santaana')), ('La puerta trasera: la flecha y el póster', shot('merkocarry_flecha_trasera')),
                                    ('El póster en el pilar de la entrada del parking', shot('merkocarry_cristo_puerta')), ('El póster junto a la entrada de clientes', shot('merkocarry_suspiro_puerta')),
                                    ('Dentro: desde la puerta de Santa Ana', shot('merkocarry_dentro_entrada')), ('Desde la puerta trasera', shot('merkocarry_dentro_fondo')),
                                    ('El pasillo central, de puerta a puerta', shot('merkocarry_dentro_pasillo')), ('La carnicería, junto a la puerta trasera', shot('merkocarry_dentro_carniceria')),
                                    ('Las cajas', shot('merkocarry_dentro_cajas')), ('Recién entrado, con la salida', shot('merkocarry_dentro_jugador'))], 800, 450, 2)
sheet('03_noche_y_aire.jpg', [('A las 22:00, cerrado', shot('merkocarry_santaana_noche')), ('La entrada del parking, cerrada', shot('merkocarry_cristo_puerta_noche')),
                              ('El aparcamiento, de noche', shot('merkocarry_aparcamiento_noche')), ('La entrada de clientes, cerrada', shot('merkocarry_suspiro_puerta_noche')),
                              ('Desde el aire, por Magallanes', shot('merkocarry_aire')), ('Desde el aire, por Santa Ana', shot('merkocarry_aire_norte'))], 800, 450, 2)
