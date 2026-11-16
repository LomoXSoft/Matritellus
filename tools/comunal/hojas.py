"""The sheets shown to the user of the people's university of the Calle de los Arcos and the stationer's (guion/fotos/universidad_comunal/).

    python tools/comunal/hojas.py [SV_FOLDER]        (the Street View pictures fetched by capturas.py)

01: Street View (November 2024) beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/comunal/vistas.py SV_FOLDER b c d c_tienda a)").
02: the game's own pictures (tools/run_tests.py comunal).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'universidad_comunal')
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
    pairs('01_street_view_y_juego.jpg', (('b', 'el porche y la tapia'), ('c', 'la tapia sur y la fachada'), ('a', 'desde el norte'), ('d', 'la papelería'), ('c_tienda', 'la papelería, desde el norte')))
sheet('02_en_el_juego.jpg', [('El porche', shot('comunal_porche')), ('El rótulo', shot('comunal_rotulo')), ('El tablón', shot('comunal_tablon')), ('La tapia y la fachada', shot('comunal_tapia')),
                             ('Desde el norte', shot('comunal_desde_norte')), ('Desde el sur', shot('comunal_desde_sur')), ('La papelería', shot('comunal_papeleria')), ('Su rótulo', shot('comunal_papeleria_rotulo')),
                             ('La papelería abierta (lunes, 12:30)', shot('comunal_papeleria_arco')), ('Cerrada a mediodía (lunes, 15:30)', shot('comunal_papeleria_cerrada')), ('Por detrás, calle Cervantes', shot('comunal_cervantes')), ('Desde el aire', shot('comunal_aire'))], 800, 450, 2)
sheet('03_papeleria_rocas.jpg', [('Lunes, 12:30: abierta', shot('comunal_papeleria_arco')), ('Desde la puerta', shot('comunal_papeleria_dentro')),
                                  ('Lunes, 15:30: cerrada (abre a las 17:30)', shot('comunal_papeleria_cerrada')), ('Lunes, 20:00: abierta', shot('comunal_papeleria_tarde')),
                                  ('Lunes, 20:00, desde la puerta', shot('comunal_papeleria_tarde_dentro')), ('Domingo, 12:00: cerrada', shot('comunal_papeleria_domingo'))], 800, 450, 2)
sheet('04_papeleria_rocas_por_dentro.jpg', [('Al entrar', shot('comunal_tienda_entrada')), ('Desde el mostrador, hacia la puerta', shot('comunal_tienda_puerta')),
                                             ('Los libros', shot('comunal_tienda_libros')), ('La papelería', shot('comunal_tienda_papeleria')),
                                             ('El mostrador', shot('comunal_tienda_mostrador')), ('La prensa', shot('comunal_tienda_prensa')),
                                             ('Las mochilas', shot('comunal_tienda_mochilas')), ('Desde arriba', shot('comunal_tienda_alto'))], 800, 450, 2)
