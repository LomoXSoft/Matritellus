"""The sheets shown to the user of the fairground and market (guion/fotos/ferial/).

    python tools/ferial/hojas.py [SV_FOLDER]            (the Street View pictures fetched by capturas.py)

01: Street View (March 2013 inside, November 2024 round it) beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/merkocarry/vistas.py SV_FOLDER f3 a7 p1 w1 m2 e3 q3 q4 s2 h1 s5)").
02: the game (tools/run_tests.py ferial): by day, at night, from the air.
03: the park by the Paseo del Cristo.
04: the Auditorio and the public toilets, Street View beside the game from the same spots (run first:
    tools/run_tests.py "$(python tools/merkocarry/vistas.py SV_FOLDER w1t w3t u1 u5 u6 u7 u8)"); 05: their game shots
    and the toilets' inside.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'ferial')
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
    for n, what in (('f3', 'la fuente de la rotonda (2013)'), ('a7', 'la pérgola de hiedra (2013)'), ('p1', 'la explanada del mercadillo (2013)'),
                    ('e3', 'la explanada desde la carretera (2024)'), ('w1', 'el camino de poniente (2013)'), ('m2', 'el camino del medio (2013)'),
                    ('q3', 'el parque desde el Paseo del Cristo (2024)'), ('q4', 'la fuente ovalada (2024)'), ('s2', 'la pérgola y la fuentecilla, desde el recinto (2013)'),
                    ('h1', 'la pérgola de la calle Huerta (2024)'), ('s5', 'el quiosco de la esquina (2024)')):
        rows.append(('Street View: ' + what, Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('La fuente de la rotonda', shot('ferial_fuente_cerca')), ('La entrada de la fuente', shot('ferial_fuente')),
                             ('La pérgola de hiedra', shot('ferial_pergola')), ('Bajo la pérgola', shot('ferial_pergola_dentro')),
                             ('La explanada del mercadillo', shot('ferial_plaza')), ('Los tres caminos, con su tierra', shot('ferial_caminos')),
                             ('De noche: las farolas', shot('ferial_caminos_noche')), ('De noche: la fuente', shot('ferial_fuente_noche')),
                             ('Desde el aire', shot('ferial_aire')), ('Desde el aire, por el norte', shot('ferial_aire_norte'))], 800, 450, 2)
sheet('03_parque_paseo_del_cristo.jpg', [('La calle principal del recinto: asfalto en el recinto, empedrado en el parque', shot('ferial_eje_aire')),
                                          ('Desde la calle del recinto: el camino bajo la hiedra, las terrazas a los lados', shot('ferial_eje')), ('Desde la fuente ovalada: el camino empedrado bajo la hiedra', shot('ferial_eje_parque')),
                                          ('Desde el Paseo del Cristo', shot('ferial_parque')), ('La fuente ovalada', shot('ferial_parque_este')),
                                          ('La pérgola en semicírculo', shot('ferial_parque_oeste')), ('La terraza del bloque de poniente', shot('ferial_parque_sur')),
                                          ('La terraza del bloque de levante', shot('ferial_parque_fuentecilla')), ('La pérgola de la calle Huerta', shot('ferial_parque_huerta')),
                                          ('El quiosco de la esquina', shot('ferial_parque_kiosco')), ('Desde el aire', shot('ferial_parque_aire'))], 800, 450, 2)
BLUR = {'w1t': [(135, 370, 195, 445)], 'u6': [(640, 355, 710, 440), (985, 370, 1024, 445)]}   # the people in them (no faces shown)


def sv_pic(n):
    im = Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
    for b in BLUR.get(n, []):
        im.paste(im.crop(b).resize((4, 4)).resize((b[2] - b[0], b[3] - b[1])).filter(ImageFilter.GaussianBlur(6)), b[:2])
    return im


if sv:
    rows = []
    for n, what in (('w1t', 'los aseos desde el final de la calle'), ('w3t', 'los aseos y el muro blanco desde el aparcamiento (2024)'),
                    ('u5', 'el muro desde la carretera (2013)'),
                    ('u7', 'el muro y la curva desde la carretera (2013)'), ('u8', 'la curva desde la rotonda (2013)'), ('u1', 'el muro del sur (2013)')):
        rows.append(('Street View: ' + what, sv_pic(n)))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('04_auditorio_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('05_auditorio_y_aseos.jpg', [('El Auditorio desde el aire', shot('ferial_aud_aire')), ('Dentro: las gradas, los postes con focos', shot('ferial_aud_dentro')),
                                   ('El escenario de piedra, desde las gradas', shot('ferial_aud_gradas')), ('El escenario y su escalera, junto a la entrada', shot('ferial_aud_escenario')),
                                   ('El hueco del muro junto a los aseos', shot('ferial_aud_hueco')), ('El poyo al pie del muro, para sentarse', shot('ferial_aud_poyo')),
                                   ('Los aseos desde la calle', shot('ferial_aud_calle')), ('Los aseos: la puerta doble con la flecha verde', shot('ferial_aseos_flecha')),
                                   ('El muro blanco del aparcamiento, con sus carteles', shot('ferial_aud_carteles')), ('La curva del muro, con su acera', shot('ferial_aud_curva')),
                                   ('Dentro de los aseos', shot('ferial_aseos_dentro')), ('Los lavabos', shot('ferial_aseos_lavabos')),
                                   ('Hacia la puerta', shot('ferial_aseos_puerta')), ('De noche', shot('ferial_aud_dentro_noche'))], 800, 450, 2)
