"""The pictures the Noche is painted with (godot/assets/noche/), all drawn here. The user, 17 November 2026, with a
picture of the shop as it was: "Mismos colores y diseños, pero que ponga noche y el logotipo en vez de un porcentaje,
una luna" -- the red board with the name in white and, in the white-edged square beside it, a moon instead of the per
cent sign; the strip of lime green under it; the red square sign standing out from the wall.

    python tools/noche/dibujos.py

rotulo.png     the board over the door: red, "Noche" in white, the square with the moon (2.45 x 0.49 m)
mercado.png    the strip under it: lime green, "MARKET" in red (2.45 x 0.19 m)
banderola.png  each face of the square sign standing out from the wall: red, the square with the moon (0.6 x 0.6 m)
logo.png       the name and the moon alone, red on white (inside, on the back wall)
cartel.png     the board of offers on the pavement: yellow, red, a price
horario.png    the plate of its hours by the door
persiana.png   the roller shutter's slats, grey (one metre of it)
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'noche')
FONTS = os.path.join(os.environ.get('WINDIR', 'C:\\Windows'), 'Fonts')
ROUND = os.path.join(FONTS, 'segoeuib.ttf')
BLACK = os.path.join(FONTS, 'ariblk.ttf')
BOLD = os.path.join(FONTS, 'arialbd.ttf')
RED = (214, 32, 42)
WHITE = (250, 250, 248)
LIME = (178, 206, 52)
os.makedirs(OUT, exist_ok=True)


def save(im, name):
    im.save(os.path.join(OUT, name))
    print(name, im.size)


def moon_square(d, x, y, s, fg, bg):
    """the square with the moon: a white edge with rounded corners, a crescent inside"""
    w = max(3, int(s * 0.07))
    d.rounded_rectangle([x, y, x + s, y + s], radius=int(s * 0.16), outline=fg, width=w)
    c = (x + s * 0.5, y + s * 0.5)
    r = s * 0.3
    d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=fg)
    o = (c[0] + r * 0.45, c[1] - r * 0.3)                    # bitten out by the background: a crescent opening to the right
    r2 = r * 0.86
    d.ellipse([o[0] - r2, o[1] - r2, o[0] + r2, o[1] + r2], fill=bg)
    for k, (sx, sy, sr) in enumerate(((0.69, 0.37, 0.035), (0.84, 0.62, 0.025))):      # two little stars, clear of it
        px, py, pr = x + s * sx, y + s * sy, s * sr
        d.polygon([(px, py - pr * 2.2), (px + pr * 0.6, py - pr * 0.6), (px + pr * 2.2, py), (px + pr * 0.6, py + pr * 0.6),
                   (px, py + pr * 2.2), (px - pr * 0.6, py + pr * 0.6), (px - pr * 2.2, py), (px - pr * 0.6, py - pr * 0.6)], fill=fg)


def rotulo():
    W, H = 1225, 245                                           # 500 px a metre
    im = Image.new('RGB', (W, H), RED)
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(ROUND, 190)
    tw = d.textlength('Noche', font=f)
    s = 170
    gap = 45
    x0 = (W - tw - gap - s) / 2
    d.text((x0, H / 2 + 6), 'Noche', font=f, fill=WHITE, anchor='lm')
    moon_square(d, x0 + tw + gap, (H - s) / 2, s, WHITE, RED)
    save(im, 'rotulo.png')


def mercado():
    W, H = 1225, 95
    im = Image.new('RGB', (W, H), LIME)
    d = ImageDraw.Draw(im)
    d.text((W / 2, H / 2), 'MARKET', font=ImageFont.truetype(BOLD, 64), fill=RED, anchor='mm')
    save(im, 'mercado.png')


def banderola():
    W = 300
    im = Image.new('RGB', (W, W), RED)
    d = ImageDraw.Draw(im)
    moon_square(d, 55, 55, 190, WHITE, RED)
    save(im, 'banderola.png')


def logo():
    W, H = 1400, 300
    im = Image.new('RGB', (W, H), WHITE)
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(ROUND, 220)
    tw = d.textlength('Noche', font=f)
    s = 200
    x0 = (W - tw - 50 - s) / 2
    d.text((x0, H / 2 + 8), 'Noche', font=f, fill=RED, anchor='lm')
    moon_square(d, x0 + tw + 50, (H - s) / 2, s, RED, WHITE)
    save(im, 'logo.png')


def cartel():
    W, H = 300, 420
    im = Image.new('RGB', (W, H), (242, 196, 40))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W, 70], fill=RED)
    d.text((W / 2, 36), 'OFERTA', font=ImageFont.truetype(BLACK, 48), fill=WHITE, anchor='mm')
    d.rectangle([30, 100, W - 30, 230], fill=(250, 236, 180))
    for k, t in enumerate(('Leche', 'entera', '1 litro')):
        d.text((W / 2, 128 + k * 36), t, font=ImageFont.truetype(BOLD, 32), fill=(40, 40, 40), anchor='mm')
    d.rectangle([0, 260, W, H], fill=RED)
    d.text((W / 2, 342), '0,79€', font=ImageFont.truetype(BLACK, 92), fill=WHITE, anchor='mm')
    save(im, 'cartel.png')


def horario():
    W, H = 260, 200
    im = Image.new('RGB', (W, H), WHITE)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W, 46], fill=RED)
    d.text((W / 2, 24), 'HORARIO', font=ImageFont.truetype(BOLD, 30), fill=WHITE, anchor='mm')
    f = ImageFont.truetype(BOLD, 24)
    d.text((W / 2, 86), 'Lunes a sábado', font=f, fill=(40, 40, 40), anchor='mm')
    d.text((W / 2, 120), '9:00 - 21:30', font=f, fill=(40, 40, 40), anchor='mm')
    d.text((W / 2, 166), 'Domingo cerrado', font=f, fill=RED, anchor='mm')
    save(im, 'horario.png')


def persiana():
    W, H = 128, 256                                            # 1 m: slats of 6.25 cm
    im = Image.new('RGB', (W, H))
    d = ImageDraw.Draw(im)
    for y in range(H):
        t = (y % 16) / 16.0
        v = 168 if t < 0.12 else (196 if t < 0.55 else (184 if t < 0.88 else 150))
        d.line([(0, y), (W, y)], fill=(v, v, v + 4))
    save(im, 'persiana.png')


if __name__ == '__main__':
    rotulo(); mercado(); banderola(); logo(); cartel(); horario(); persiana()
