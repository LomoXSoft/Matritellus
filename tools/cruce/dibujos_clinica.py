"""The pictures of the dental clinic of the crossroads of the traffic lights (godot/assets/clinica/), drawn here. The
user, 22 November 2026: "Vamos con el dentista. Lo llamaremos \"Clínica Dental\" y \"Dr. Josué Escudero\"" (the real
one: big steel letters on dark stone, the dentist's name under them). All of them the game's own.

    python tools/cruce/dibujos_clinica.py

rotulo_largo.png   CLÍNICA DENTAL in one line, for the front on the Calle Cervantes: pale steel letters, their depth
rotulo_corto.png   CLÍNICA / DENTAL in two lines, for the front on the Arcos
doctor.png         Dr. Josué Escudero, the smaller letters under the name
logo.png           the mark by the corner: a tooth and a smile under it
vinilo.png         the words on the big window's mirror glass, in greens and white: what the clinic does
vinilo2.png        the other window: the clinic's name, the doctor's, a green stroke
placa_arcos.png, placa_santa_ana.png, placa_salvador.png    the street's tiles (the second is on the cream house
                   opposite, mirador.gd; the third on the house north of the Salvador, beige.gd)
After adding or changing them: Godot --headless --path godot --import.
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'clinica')
os.makedirs(OUT, exist_ok=True)
STEEL = (232, 226, 210, 255)
DEPTH = (84, 72, 62, 255)
GREEN = (120, 190, 60, 235)
DARKGREEN = (60, 140, 70, 235)
WHITE = (248, 248, 244, 235)
I_ACUTE, U_ACUTE, E_ACUTE, O_ACUTE = 'Í', 'ú', 'é', 'ó'


def font(names, size):
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


SERIF = ['georgiab.ttf', 'timesbd.ttf']
BOLD = ['arialbd.ttf']
ITALIC = ['arialbi.ttf', 'arialbd.ttf']


def letters(text, size, gap=10, lean=0.14):
    """raised letters: each drawn pale over its own depth (a darker copy down and to the right), set a little apart and
    leaning forward"""
    f = font(SERIF, size)
    d0 = ImageDraw.Draw(Image.new('RGBA', (8, 8)))
    w = int(sum(d0.textlength(ch, font=f) + gap for ch in text)) + 40
    h = int(size * 1.5)
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for dx, dy, col in ((7, 8, DEPTH), (4, 5, DEPTH), (0, 0, STEEL)):
        x = 12
        for ch in text:
            d.text((x + dx, int(size * 0.18) + dy), ch, font=f, fill=col)
            x += d.textlength(ch, font=f) + gap
    im = im.transform(im.size, Image.AFFINE, (1, lean, -lean * h / 2, 0, 1, 0), resample=Image.BICUBIC)
    return im.crop(im.getbbox())


def fit(piece, w, h):
    k = min(w / piece.size[0], h / piece.size[1])
    return piece.resize((max(1, int(piece.size[0] * k)), max(1, int(piece.size[1] * k))), Image.LANCZOS)


def centre(im, piece, y):
    im.alpha_composite(piece, ((im.size[0] - piece.size[0]) // 2, y))


def rotulo_largo():
    im = Image.new('RGBA', (2048, 256), (0, 0, 0, 0))
    centre(im, fit(letters('CL%sNICA DENTAL' % I_ACUTE, 190, 16), 2000, 236), 10)
    im.save(os.path.join(OUT, 'rotulo_largo.png'))


def rotulo_corto():
    im = Image.new('RGBA', (1216, 512), (0, 0, 0, 0))
    a = fit(letters('CL%sNICA' % I_ACUTE, 190, 14), 1180, 236)
    b = fit(letters('DENTAL', 190, 14), 1180, 236)
    k = min(1.0, a.size[1] / b.size[1])
    b = b.resize((int(b.size[0] * k), int(b.size[1] * k)), Image.LANCZOS)
    im.alpha_composite(a, (20, 8))
    im.alpha_composite(b, (1216 - b.size[0] - 20, 268))
    im.save(os.path.join(OUT, 'rotulo_corto.png'))


def doctor():
    im = Image.new('RGBA', (1024, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    f = font(BOLD, 86)
    t = 'Dr. Josu%s Escudero' % E_ACUTE
    x = (1024 - d.textlength(t, font=f)) / 2
    d.text((x + 3, 16 + 4), t, font=f, fill=DEPTH)
    d.text((x, 16), t, font=f, fill=STEEL)
    im.save(os.path.join(OUT, 'doctor.png'))


def tooth(d, cx, cy, s, col, width):
    """the outline of a molar: a crown with two bumps, two roots"""
    pts = []
    for i in range(41):
        t = i / 40.0
        ang = math.pi * (1.0 + t)                                   # the crown: half an oval, with a dip in its top
        x = math.cos(ang) * s * 0.5
        y = math.sin(ang) * s * 0.42 + math.exp(-((t - 0.5) * 7) ** 2) * s * 0.1
        pts.append((cx + x, cy + y))
    pts += [(cx + s * 0.46, cy + s * 0.2), (cx + s * 0.3, cy + s * 0.78), (cx + s * 0.14, cy + s * 0.3), (cx, cy + s * 0.24),
            (cx - s * 0.14, cy + s * 0.3), (cx - s * 0.3, cy + s * 0.78), (cx - s * 0.46, cy + s * 0.2)]
    d.line(pts + pts[:1], fill=col, width=width, joint='curve')


def logo():
    im = Image.new('RGBA', (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for dx, dy, col in ((5, 6, DEPTH), (0, 0, STEEL)):
        tooth(d, 256 + dx, 190 + dy, 250, col, 16)
        d.arc([96 + dx, 250 + dy, 416 + dx, 470 + dy], 25, 155, fill=col, width=16)      # the smile under it
    im.save(os.path.join(OUT, 'logo.png'))


def vinilo():
    w, h = 1024, 768
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.pieslice([-420, 380, 900, 1500], 180, 360, fill=(120, 190, 60, 70))      # a pale green swell across the foot
    words = [('Cirug%sa oral' % 'í', 60, 80, 96, GREEN), ('Pr%stesis' % O_ACUTE, 610, 96, 84, DARKGREEN),
             ('Ortodoncia', 250, 228, 80, WHITE), ('Implantes', 390, 350, 124, GREEN),
             ('Est%stica dental' % E_ACUTE, 70, 500, 88, WHITE), ('Periodoncia', 540, 610, 82, DARKGREEN)]
    for t, x, y, size, col in words:
        d.text((x, y), t, font=font(ITALIC if col != WHITE else BOLD, size), fill=col)
    im.save(os.path.join(OUT, 'vinilo.png'))


def vinilo2():
    w, h = 768, 768
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.arc([60, 120, 700, 520], 200, 340, fill=GREEN, width=22)
    d.arc([100, 170, 660, 560], 205, 335, fill=DARKGREEN, width=10)
    f = font(BOLD, 74)
    for i, t in enumerate(('CL%sNICA DENTAL' % I_ACUTE,)):
        d.text(((w - d.textlength(t, font=f)) / 2, 380), t, font=f, fill=WHITE)
    f2 = font(ITALIC, 54)
    t = 'Dr. Josu%s Escudero' % E_ACUTE
    d.text(((w - d.textlength(t, font=f2)) / 2, 480), t, font=f2, fill=GREEN)
    im.save(os.path.join(OUT, 'vinilo2.png'))


def placa(name, top, bottom):
    w, h = 360, 280
    im = Image.new('RGBA', (w, h), (244, 242, 234, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([5, 5, w - 6, h - 6], outline=(40, 60, 120), width=5)
    d.rectangle([14, 14, w - 15, h - 15], outline=(40, 60, 120), width=2)
    cx, cy = w // 2, 62                                  # the same little shield as the other tiles: a saffron flower
    d.polygon([(cx - 26, cy - 30), (cx + 26, cy - 30), (cx + 26, cy + 8), (cx, cy + 32), (cx - 26, cy + 8)], fill=(250, 248, 240), outline=(40, 60, 120))
    for a in range(6):
        ang = math.radians(a * 60 + 30)
        px, py = cx + 13 * math.cos(ang), cy - 4 + 13 * math.sin(ang)
        d.ellipse([px - 8, py - 8, px + 8, py + 8], fill=(150, 100, 190))
    d.ellipse([cx - 5, cy - 9, cx + 5, cy + 1], fill=(230, 120, 30))
    f = font(SERIF, 52)
    for i, ln in enumerate((top, bottom)):
        d.text(((w - d.textlength(ln, font=f)) / 2, 112 + i * 70), ln, font=f, fill=(24, 30, 52))
    im.save(os.path.join(OUT, name))


if __name__ == '__main__':
    rotulo_largo(); rotulo_corto(); doctor(); logo(); vinilo(); vinilo2()
    placa('placa_arcos.png', 'Calle', 'Arcos')
    placa('placa_santa_ana.png', 'Calle', 'Santa Ana')      # (for the cream house with the bay window: mirador.gd)
    placa('placa_salvador.png', 'Calle', 'Salvador')        # (for the house north of the Salvador: beige.gd)
    print(sorted(os.listdir(OUT)))
