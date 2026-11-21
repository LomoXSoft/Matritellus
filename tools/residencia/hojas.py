"""The sheets shown to the user of the old people's home of the Cristo del Prado (guion/fotos/residencia/).

    python tools/residencia/hojas.py [SV_FOLDER] [fotos=FOLDER]

01: Street View beside the game from the same spots (run first, SV_FOLDER made by tools/residencia/capturas.py:
    tools/run_tests.py "$(python tools/merkocarry/vistas.py SV_FOLDER e1 e2 e3 e6 n1 n4 w2 w4 p1)").
    (The far passers-by of n4 are blurred.)
02: the game (tools/run_tests.py residencia): along the east arm of the Calle del Cristo, its main door, the north end,
    the west arm, the low wing on the square, from the air, at night.
03: the user's 360° photos of the low wing and the home's gate (21 November 2026, from Google Maps on the phone; NOT
    kept in the repository: FOLDER holds f1.jpg along the wing, f3.jpg into the porch, f5.jpg the gate, the phone's
    bars cropped off) beside the game from about the same spots (the vistas sv_goeste, sv_gdentro, sv_gpuerta,
    sv_gporche: see referencias/cristoprado/LEEME.md).
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SHOTS = os.path.join(HERE, '..', '..', 'godot', 'shots')
OUT = os.path.join(HERE, '..', '..', 'guion', 'fotos', 'residencia')
os.makedirs(OUT, exist_ok=True)
args = [a for a in sys.argv[1:] if not a.startswith('fotos=')]
fotos = ([a[6:] for a in sys.argv[1:] if a.startswith('fotos=')] or [''])[0]
sv = args[0] if args else ''
try:
    font = ImageFont.truetype('arial.ttf', 17)
except Exception:
    font = ImageFont.load_default()
BLUR = {'n4': [(560, 440, 620, 560)]}           # (in the 1024 x 640 picture)


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


def street(n):
    im = Image.open(os.path.join(sv, n + '.jpg')).convert('RGB')
    for box in BLUR.get(n, []):
        sx, sy = im.size[0] / 1024.0, im.size[1] / 640.0
        b = (int(box[0] * sx), int(box[1] * sy), int(box[2] * sx), int(box[3] * sy))
        im.paste(im.crop(b).filter(ImageFilter.GaussianBlur(10)), b)
    return im


if sv:
    rows = []
    for n, what in (('e1', 'la Calle del Cristo desde el Paseo (2024)'), ('e2', 'la entrada principal (2024)'),
                    ('e3', 'la fachada este (2024)'), ('e6', 'la punta norte (2024)'), ('n1', 'sus ventanas, de cerca (2024)'),
                    ('n4', 'la esquina noroeste (2013)'), ('w2', 'el brazo oeste (2013)'), ('w4', 'el ala baja, de cerca (2013)'),
                    ('p1', 'el ala baja y su porche, desde la placita (2013)')):
        rows.append(('Street View: ' + what, street(n)))
        rows.append(('El juego, desde el mismo sitio', shot('vista_sv_' + n)))
    sheet('01_street_view_y_juego.jpg', rows, 800, 500, 2)
sheet('02_en_el_juego.jpg', [('Por la Calle del Cristo', shot('residencia_este')), ('La entrada principal', shot('residencia_entrada')),
                             ('La punta norte', shot('residencia_norte')), ('El brazo oeste', shot('residencia_oeste')),
                             ('El ala baja, en la placita', shot('residencia_ala')), ('Desde el aire', shot('residencia_aire')),
                             ('De noche', shot('residencia_este_noche'))], 800, 450, 2)

def row_sheet(name, rows, h):
    """each row: a photo standing up beside a picture of the game, at height h"""
    ims = []
    for label, a, b in rows:
        wa = int(a.size[0] * h / a.size[1]); wb = int(b.size[0] * h / b.size[1])
        ims.append((label, a.resize((wa, h), Image.LANCZOS), b.resize((wb, h), Image.LANCZOS)))
    w = max(a.size[0] + b.size[0] + 6 for _, a, b in ims)
    out = Image.new('RGB', (w, len(ims) * (h + 26)), (22, 22, 24))
    d = ImageDraw.Draw(out)
    for i, (label, a, b) in enumerate(ims):
        y = i * (h + 26)
        d.text((6, y + 4), label, fill=(240, 240, 240), font=font)
        out.paste(a, (0, y + 26)); out.paste(b, (a.size[0] + 6, y + 26))
    path = os.path.join(OUT, name)
    out.save(path, quality=90)
    print(path, out.size)


if fotos:
    def foto(n):
        im = Image.open(os.path.join(fotos, n + '.jpg')).convert('RGB')
        k = im.size[1] / 2000.0                        # (the phone's screen: its bars above and below cropped off)
        return im.crop((0, int(215 * k), im.size[0], int(1490 * k)))   # (and the viewer's button)
    row_sheet('03_ala_fotos_360.jpg', [
        ('Tu foto 360: a lo largo del ala  |  el juego', foto('f1'), shot('vista_sv_goeste')),
        ('Tu foto 360: el porche por dentro  |  el juego', foto('f3'), shot('vista_sv_gdentro')),
        ('Tu foto 360: la puerta de la Residencia  |  el juego', foto('f5'), shot('vista_sv_gpuerta')),
        ('El porche desde la placita (juego)  |  desde arriba', shot('vista_sv_gporche').crop((280, 0, 1000, 720)), shot('vista_sv_garriba'))], 560)
