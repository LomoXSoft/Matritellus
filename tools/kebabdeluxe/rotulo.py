"""The signs of Kebab Deluxe (the user's name for the kebab house of the Avenida de Castilla-La Mancha), drawn here
in the game's flat look -- nobody's photograph or logo: after the user's photo of the real one only in what goes where
(the user, 16 November 2026: they took La Meseta's badges down and put their own board up).

    python tools/kebabdeluxe/rotulo.py

Writes into godot/assets/kebabdeluxe/:
  rotulo.png      the lit board over the shopfront: food on fire at the ends, the name in script, a yellow ribbon of
                  what it sells, and the telephone numbers -- scribbles, as on every sign of the game
  bandera.png     the lit board that hangs out over the pavement (both its faces are this)
  montante.png    the four pictures of burgers over the doors, side by side
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'kebabdeluxe')
FONTS = os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts')
SCRIPT = os.path.join(FONTS, 'segoescb.ttf')       # (the game's title is in it too: tools/make_titulo.py)
BOLD = os.path.join(FONTS, 'arialbd.ttf')
NAME = 'Kebab Deluxe'
SELLS = 'PIZZAS · TACOS · POLLO ASADO'
rnd = random.Random(1712)


def fire(d, x0, y0, x1, y1):
    """flames licking up from the bottom of a box"""
    for i in range(60):
        x = rnd.uniform(x0, x1)
        h = rnd.uniform(0.35, 1.0) * (y1 - y0)
        w = rnd.uniform(18, 46)
        col = rnd.choice([(232, 64, 26), (246, 128, 32), (250, 186, 40), (200, 34, 20)])
        d.polygon([(x - w / 2, y1), (x + w / 2, y1), (x + rnd.uniform(-10, 10), y1 - h)], fill=col)


def pizza(d, cx, cy, r):
    d.ellipse([cx - r, cy - r * 0.62, cx + r, cy + r * 0.62], fill=(214, 150, 74))
    d.ellipse([cx - r * 0.86, cy - r * 0.52, cx + r * 0.86, cy + r * 0.52], fill=(232, 196, 92))
    for i in range(9):
        a = rnd.uniform(0, math.tau); q = rnd.uniform(0.1, 0.7)
        x, y = cx + math.cos(a) * r * 0.8 * q, cy + math.sin(a) * r * 0.48 * q
        d.ellipse([x - r * 0.12, y - r * 0.08, x + r * 0.12, y + r * 0.08], fill=(186, 44, 36))
    for i in range(6):
        a = rnd.uniform(0, math.tau); q = rnd.uniform(0.1, 0.7)
        x, y = cx + math.cos(a) * r * 0.8 * q, cy + math.sin(a) * r * 0.48 * q
        d.ellipse([x - r * 0.06, y - r * 0.04, x + r * 0.06, y + r * 0.04], fill=(62, 120, 48))


def doner(d, cx, cy, h):
    """the spit: a fat cone of meat on its skewer"""
    d.rectangle([cx - 3, cy - h * 0.62, cx + 3, cy + h * 0.55], fill=(170, 170, 176))
    d.polygon([(cx - h * 0.2, cy - h * 0.45), (cx + h * 0.2, cy - h * 0.45), (cx + h * 0.14, cy + h * 0.45), (cx - h * 0.14, cy + h * 0.45)], fill=(150, 82, 40))
    for k in range(7):
        y = cy - h * 0.4 + k * h * 0.12
        d.line([(cx - h * 0.18, y), (cx + h * 0.18, y + 4)], fill=(112, 56, 26), width=3)


def burger(d, cx, cy, w):
    d.chord([cx - w / 2, cy - w * 0.42, cx + w / 2, cy + w * 0.12], 180, 360, fill=(214, 146, 64))
    for k in range(7):
        x = cx - w * 0.3 + k * w * 0.1
        d.ellipse([x - 2, cy - w * 0.3, x + 2, cy - w * 0.27], fill=(250, 236, 200))
    d.rectangle([cx - w * 0.52, cy - w * 0.06, cx + w * 0.52, cy - w * 0.0], fill=(84, 160, 60))
    d.rectangle([cx - w * 0.48, cy - w * 0.0, cx + w * 0.48, cy + w * 0.05], fill=(246, 196, 40))
    d.rounded_rectangle([cx - w * 0.5, cy + w * 0.05, cx + w * 0.5, cy + w * 0.17], 6, fill=(96, 50, 30))
    d.rectangle([cx - w * 0.46, cy + w * 0.17, cx + w * 0.46, cy + w * 0.21], fill=(200, 50, 40))
    d.rounded_rectangle([cx - w * 0.5, cy + w * 0.21, cx + w * 0.5, cy + w * 0.32], 8, fill=(214, 146, 64))


def fries(d, cx, cy, h):
    for k in range(7):
        x = cx - h * 0.2 + k * h * 0.065
        d.rectangle([x, cy - h * 0.5 - rnd.uniform(0, h * 0.15), x + h * 0.045, cy], fill=(250, 210, 70))
    d.polygon([(cx - h * 0.28, cy - h * 0.2), (cx + h * 0.28, cy - h * 0.2), (cx + h * 0.2, cy + h * 0.4), (cx - h * 0.2, cy + h * 0.4)], fill=(206, 34, 30))


def scribble(d, x, y, w, h, col):
    """a telephone number nobody can ring"""
    pts = []
    for i in range(int(w / 7)):
        pts.append((x + i * 7, y + h / 2 + math.sin(i * 1.7) * h * 0.38 + rnd.uniform(-2, 2)))
    d.line(pts, fill=col, width=max(2, int(h / 7)))


def text(d, at, s, font, fill, stroke=0, sfill=(0, 0, 0), anchor='mm'):
    d.text(at, s, font=font, fill=fill, anchor=anchor, stroke_width=stroke, stroke_fill=sfill)


def board(w, h):
    im = Image.new('RGB', (w, h), (26, 14, 16))
    d = ImageDraw.Draw(im)
    for y in range(h):                               # dark red to near black, top to bottom
        t = y / h
        d.line([(0, y), (w, y)], fill=(int(96 - 66 * t), int(22 - 10 * t), int(20 - 6 * t)))
    return im, d


def main():
    os.makedirs(OUT, exist_ok=True)
    # --- the board over the shopfront: 5 m by 0.8 ---
    W, H = 2000, 320
    im, d = board(W, H)
    fire(d, 0, H * 0.35, 420, H); fire(d, W - 430, H * 0.35, W, H)
    pizza(d, 190, 190, 150)
    doner(d, 360, 150, 210)
    burger(d, W - 330, 150, 190)
    fries(d, W - 150, 210, 200)
    d.ellipse([W - 470, 40, W - 400, 110], fill=(36, 120, 64), outline=(250, 220, 120), width=4)      # a little badge of its own
    text(d, (W - 435, 75), 'K', ImageFont.truetype(BOLD, 44), (250, 220, 120))
    text(d, (W / 2, 112), NAME, ImageFont.truetype(SCRIPT, 150), (252, 250, 244), 8, (40, 10, 12))
    d.polygon([(560, 196), (W - 560, 196), (W - 590, 252), (590, 252)], fill=(244, 196, 40))         # the yellow ribbon
    text(d, (W / 2, 224), SELLS, ImageFont.truetype(BOLD, 44), (150, 26, 22))
    for k, x in enumerate((640, 1090)):
        scribble(d, x, 262, 280, 40, (250, 250, 246))
    d.text((1010, 280), '-', font=ImageFont.truetype(BOLD, 40), fill=(250, 250, 246), anchor='mm')
    im = im.filter(ImageFilter.GaussianBlur(0.6))
    im.save(os.path.join(OUT, 'rotulo.png'))
    # --- the board that hangs out over the pavement: 0.9 m by 0.6 ---
    W, H = 600, 400
    im, d = board(W, H)
    fire(d, 0, H * 0.55, W, H)
    pizza(d, 470, 300, 90)
    doner(d, 110, 290, 150)
    d.ellipse([500, 24, 566, 90], fill=(36, 120, 64), outline=(250, 220, 120), width=4)
    text(d, (533, 57), 'K', ImageFont.truetype(BOLD, 40), (250, 220, 120))
    text(d, (W / 2 - 20, 104), 'Kebab', ImageFont.truetype(SCRIPT, 110), (252, 250, 244), 6, (40, 10, 12))
    text(d, (W / 2 + 10, 196), 'Deluxe', ImageFont.truetype(SCRIPT, 104), (252, 250, 244), 6, (40, 10, 12))
    scribble(d, 150, 252, 300, 26, (250, 250, 246))
    im.filter(ImageFilter.GaussianBlur(0.6)).save(os.path.join(OUT, 'bandera.png'))
    # --- the four pictures over the doors ---
    W, H = 1200, 260
    im = Image.new('RGB', (W, H), (20, 18, 18))
    d = ImageDraw.Draw(im)
    for k in range(4):
        x0 = k * W // 4
        for y in range(H):
            t = y / H
            d.line([(x0 + 6, y), (x0 + W // 4 - 6, y)], fill=(int(60 + 40 * (k % 2) - 30 * t), int(40 - 20 * t), int(30 - 14 * t)))
        burger(d, x0 + W // 8, 120 + (k % 2) * 8, 170 + (k % 3) * 14)
    im.save(os.path.join(OUT, 'montante.png'))
    print('written to', os.path.abspath(OUT))


if __name__ == '__main__':
    main()
