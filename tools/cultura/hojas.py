"""The sheets shown to the user of the block of the Casa Grande, the library and the music school
(guion/fotos/cultura/).

    python tools/cultura/hojas.py [SV_FOLDER]            (the Street View pictures fetched by capturas.py)

01: Street View beside the game from the same spots (run first: tools/run_tests.py
    "$(python tools/merkocarry/vistas.py SV_FOLDER a0_s a3_n a3_s n3_e n5_w n8_w s3_w s3_e s5_w)").
02: the game (tools/run_tests.py cultura): its fronts, the arch, at night, from the air.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'cultura')
os.makedirs(OUT, exist_ok=True)
sv = sys.argv[1] if len(sys.argv) > 1 else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()
BLUR = {'n8_w': [(0.53, 0.69, 0.565, 0.8)]}      # (fractions of a picture where a passer-by is: no faces shown)


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


def sv_pic(n):
    im = Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
    for b in BLUR.get(n, []):
        box = (int(b[0] * im.size[0]), int(b[1] * im.size[1]), int(b[2] * im.size[0]), int(b[3] * im.size[1]))
        im.paste(im.crop(box).resize((3, 3)).resize((box[2] - box[0], box[3] - box[1])).filter(ImageFilter.GaussianBlur(6)), box[:2])
    return im


if sv:
    rows = []
    for n, what in (('a0_s', 'la Casa Grande por los Arcos (2024)'), ('a3_n', 'su portada y el escudo (2024)'), ('a3_s', 'hacia el arco (2024)'),
                    ('n3_e', 'por Argentina, hacia la biblioteca (2024)'), ('n4', 'la entrada de la biblioteca, de frente (2024)'), ('n5_w', 'la puerta de la biblioteca (2024)'), ('n8_w', 'la escuela de música desde el aparcamiento (2024)'), ('n8_este', 'su entrada, por el aparcamiento (2024)'),
                    ('s3_w', 'el Callejón Pando hacia el arco (2019)'), ('s3_e', 'el Pando, biblioteca y escuela (2019)'), ('s5_w', 'la escuela por el Pando (2019)')):
        rows.append(('Street View: ' + what, sv_pic(n)))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('La Casa Grande por los Arcos', shot('cultura_arcos')), ('Desde la esquina con Argentina', shot('cultura_arcos_norte')),
                             ('Los Arcos hacia el norte', shot('cultura_arcos_sur')), ('El arco y su torrecilla', shot('cultura_arco')),
                             ('El arco desde el Callejón Pando', shot('cultura_arco_dentro')), ('Por Argentina', shot('cultura_argentina')),
                             ('La puerta de la biblioteca', shot('cultura_biblioteca')), ('Argentina hacia el oeste', shot('cultura_argentina_oeste')),
                             ('La escuela de música', shot('cultura_musica')), ('Su fachada al aparcamiento', shot('cultura_aparcamiento')),
                             ('La curva de su sala', shot('cultura_curva')), ('El Callejón Pando', shot('cultura_pando')),
                             ('El Pando hacia el arco', shot('cultura_pando_oeste')), ('De noche, por los Arcos', shot('cultura_arcos_noche')),
                             ('Desde el aire', shot('cultura_aire')), ('Desde el aire, por el noreste', shot('cultura_aire_ne')),
                             ('La portada', shot('cultura_portada')), ('El escudo (tools/cultura/escudo.py)', shot('cultura_escudo')),
                             ('La entrada de la biblioteca, desde el este', shot('cultura_entrada_este')), ('Y desde el oeste', shot('cultura_entrada_oeste'))], 800, 450, 2)
# 04: the user's two pictures of the library's entrance beside the game (scratchpad only)
fotos = sys.argv[3] if len(sys.argv) > 3 else ''
if fotos:
    a, b = fotos.split(';')
    keep = OUT
    OUT = os.path.dirname(os.path.abspath(sys.argv[2])) if len(sys.argv) > 2 else OUT
    sheet('04_entrada_biblioteca.jpg', [('Tu foto: la entrada desde el este', Image.open(a).convert('RGB').crop((0, 690, 909, 1420))), ('El juego', shot('cultura_entrada_este')),
                                        ('Tu foto: desde el oeste', Image.open(b).convert('RGB').crop((0, 640, 909, 1370))), ('El juego', shot('cultura_entrada_oeste'))], 700, 560, 2)
    OUT = keep
# 03: the town hall's photographs beside the game (only in the scratchpad: they are the town's, not kept here)
web = sys.argv[2] if len(sys.argv) > 2 else ''
if web:
    def pic(n):
        return Image.open(os.path.join(web, n)).convert('RGB')
    rows = [('Foto del Ayuntamiento: el escudo', pic('DSC_0321-917x1030.jpg')), ('El juego', shot('cultura_escudo').crop((420, 120, 880, 560))),
            ('Foto del Ayuntamiento: la esquina', pic('DSC_0832-1030x687.jpg')), ('El juego', shot('cultura_arcos_norte'))]
    out = os.path.join(os.path.dirname(os.path.abspath(web)), '03_web_y_juego.jpg')
    OUT_KEEP = OUT
    OUT = os.path.dirname(out)
    sheet('03_web_y_juego.jpg', rows, 700, 520, 2)
    OUT = OUT_KEEP
