"""The sheets shown to the user of the post office of the Calle de Zaragoza, "Correa" (guion/fotos/correos/).

    python tools/correos/hojas.py [SV_FOLDER]            (the Street View pictures fetched by capturas.py)

01: Street View (November 2024) beside the game from the same spots (run first: tools/run_tests.py
    "$(python tools/merkocarry/vistas.py SV_FOLDER n_alto n_entrada s_frente)").
02: the game (tools/run_tests.py correos).
Views with people near the camera are left out.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'correos')
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
    for n, what in (('n_alto', 'la fachada, de frente'), ('n_entrada', 'hacia la plaza: el arco del portón'), ('s_frente', 'la ventana de la esquina norte')):
        rows.append(('Street View 2024: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('De frente', shot('correos_frente')), ('Desde la plaza', shot('correos_desde_plaza')),
                             ('El portón bajo el arco', shot('correos_arco')), ('La entrada, con su rampa', shot('correos_entrada')),
                             ('Los rótulos de Correa', shot('correos_rotulos')), ('A las 19:00, cerrada', shot('correos_frente_cerrado')),
                             ('Desde el aire, con la plaza', shot('correos_aire'))], 800, 450, 2)
sheet('03_abierto_cerrado_e_interior.jpg', [('Abierta: la verja recogida', shot('correos_entrada')), ('Cerrada, al anochecer: la verja echada, los rótulos encendidos', shot('correos_entrada_cerrado')),
                                           ('La flecha verde ante la entrada', shot('correos_flecha')), ('Dentro, al entrar', shot('correos_dentro_jugador')),
                                           ('Desde la puerta', shot('correos_dentro_entrada')), ('Las ventanillas', shot('correos_dentro_mostrador')),
                                           ('Los apartados y el buzón', shot('correos_dentro_apartados')), ('Desde el fondo, hacia la puerta', shot('correos_dentro_puerta'))], 800, 450, 2)
