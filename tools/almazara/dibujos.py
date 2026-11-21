"""The almazara's pictures (godot/assets/almazara/), drawn here: the game's own lettering and badge for "González de la
Ruz" (the user's name, 21 November 2026, for Aceites García de la Cruz) -- not the real firm's: its name, its cross and
its anniversary are left out, and an olive on its sprig stands for it.

    python tools/almazara/dibujos.py

logo.png       the name with its badge, cobalt on nothing: on the long wall, on the tall nave
logo_gris.png  the same in slate, for the mural
mural.png      what is painted on the end wall on the road (14.95 x 6.6 m): the grey quarter of a circle, the fan of
               leaves on the corner, the name, the branch of olive
emblema.png    the badge alone, for the sheet of the reception nave
cartel.png     the tall banner by the shop's door
tienda.png     the board that says where the shop is
After adding or changing them: Godot --headless --path godot --import (or load() finds no loader).
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'almazara')
os.makedirs(OUT, exist_ok=True)
COBALT = (38, 72, 160)
SLATE = (74, 84, 110)
TAUPE = (196, 170, 152)
GREY = (150, 150, 146)
LEAF = (150, 160, 150)
OLIVE = (176, 150, 104)


def font(name, size):
    for n in (name, 'georgiab.ttf', 'timesbd.ttf', 'arialbd.ttf'):
        try:
            return ImageFont.truetype(n, size)
        except Exception:
            pass
    return ImageFont.load_default()


def leaf(d, at, ang, ln, wide, fill):
    """an olive leaf: a pointed oval from `at`, `ln` long, turned `ang`"""
    pts = []
    n = 14
    for i in range(n + 1):
        t = i / n
        w = math.sin(t * math.pi) ** 0.8 * wide / 2.0
        pts.append((t * ln, -w))
    for i in range(n, -1, -1):
        t = i / n
        w = math.sin(t * math.pi) ** 0.8 * wide / 2.0
        pts.append((t * ln, w))
    c, s = math.cos(ang), math.sin(ang)
    d.polygon([(at[0] + x * c - y * s, at[1] + x * s + y * c) for x, y in pts], fill=fill)


def badge(d, cx, cy, r, ink, paper=None):
    """the badge: a ring, and in it an olive hanging from a sprig of two leaves"""
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=ink, width=max(3, int(r * 0.09)), fill=paper)
    d.line([(cx - r * 0.05, cy - r * 0.62), (cx + r * 0.05, cy - r * 0.12)], fill=ink, width=max(2, int(r * 0.06)))
    leaf(d, (cx - r * 0.02, cy - r * 0.5), math.radians(200), r * 0.62, r * 0.24, ink)
    leaf(d, (cx + r * 0.02, cy - r * 0.42), math.radians(-25), r * 0.66, r * 0.25, ink)
    d.ellipse([cx - r * 0.24, cy - r * 0.14, cx + r * 0.34, cy + r * 0.62], fill=ink)
    d.ellipse([cx - r * 0.1, cy + r * 0.0, cx + r * 0.04, cy + r * 0.2], fill=paper if paper else (255, 255, 255, 0))


def name(d, x, y, k, ink):
    """the name in two lines, the second pushed in under the first; k: the height of its capitals in pixels.
    Returns where it ends on the right."""
    big = font('georgiab.ttf', int(k * 1.38))
    small = font('georgia.ttf', int(k * 0.36))
    d.text((x, y), 'González', font=big, fill=ink)
    w1 = d.textlength('González', font=big)
    d.text((x + k * 0.5, y + k * 1.66), 'D E   L A', font=small, fill=ink)
    w0 = d.textlength('D E   L A', font=small)
    d.text((x + k * 0.5 + w0 + k * 0.3, y + k * 1.0), 'Ruz', font=big, fill=ink)
    w2 = x + k * 0.5 + w0 + k * 0.3 + d.textlength('Ruz', font=big)
    return max(x + w1, w2)


def logo(path, ink):
    im = Image.new('RGBA', (1400, 520), (255, 255, 255, 0))
    d = ImageDraw.Draw(im)
    end = name(d, 30, 20, 150, ink)
    badge(d, end + 190, 250, 160, ink)
    im.crop((0, 0, int(end + 380), 520)).save(path)
    print(path, im.size)


def branch(d, a, b, bend, ink_leaf, ink_olive, k):
    """a branch of olive from a to b, bowed by `bend`, its leaves in pairs and an olive here and there"""
    n = 9
    prev = None
    for i in range(n + 1):
        t = i / n
        x = a[0] + (b[0] - a[0]) * t + math.sin(t * math.pi) * bend
        y = a[1] + (b[1] - a[1]) * t
        if prev:
            d.line([prev, (x, y)], fill=ink_leaf, width=max(3, int(k * 0.05)))
            ang = math.atan2(y - prev[1], x - prev[0])
            for side in (-1, 1):
                leaf(d, (x, y), ang + side * (0.9 - 0.3 * t), k * (0.95 - 0.35 * t), k * 0.26, ink_leaf)
            if i % 3 == 1:
                d.ellipse([x + k * 0.15, y - k * 0.5, x + k * 0.5, y - k * 0.05], fill=ink_olive)
        prev = (x, y)
    leaf(d, prev, -math.pi / 2, k * 0.6, k * 0.2, ink_leaf)


def mural():
    w, h = 2048, 904                      # 14.95 x 6.6 m: 137 px to the metre
    k = w / 14.95
    im = Image.new('RGBA', (w, h), (255, 255, 255, 0))
    d = ImageDraw.Draw(im)
    d.pieslice([-4.6 * k, h - 4.2 * k, 4.6 * k, h + 4.2 * k], 270, 360, fill=GREY + (255,))      # the grey quarter, low on the left
    for i in range(7):                                                                         # the fan of leaves on the corner
        ang = math.radians(-100 + i * 26)
        leaf(d, (1.1 * k, h - 3.6 * k), ang, 2.7 * k, 0.5 * k, TAUPE + (255,))
    d.ellipse([0.75 * k, h - 3.95 * k, 1.45 * k, h - 3.25 * k], fill=(255, 255, 255, 255))
    end = name(d, 4.3 * k, h - 4.9 * k, 0.86 * k, SLATE + (255,))
    small = font('georgia.ttf', int(0.3 * k))
    d.text((4.4 * k, h - 5.45 * k), 'A L M A Z A R A', font=small, fill=SLATE + (255,))
    branch(d, (10.6 * k, h - 0.4 * k), (13.4 * k, h - 5.6 * k), 0.9 * k, LEAF + (255,), OLIVE + (255,), 0.9 * k)
    branch(d, (11.6 * k, h - 0.9 * k), (14.3 * k, h - 3.4 * k), -0.3 * k, LEAF + (255,), OLIVE + (255,), 0.7 * k)
    im.save(os.path.join(OUT, 'mural.png'))
    print('mural.png', im.size)


def emblema():
    im = Image.new('RGBA', (512, 512), (255, 255, 255, 0))
    badge(ImageDraw.Draw(im), 256, 256, 236, (58, 110, 96, 255))
    im.save(os.path.join(OUT, 'emblema.png'))


def cartel():
    w, h = 256, 1000                      # 0.9 x 3.5 m
    im = Image.new('RGBA', (w, h), (250, 250, 246, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=(120, 130, 120, 255), width=4)
    f = font('georgiab.ttf', 30)
    green = (70, 110, 60, 255)
    for i, line in enumerate(['ACEITE', 'DE OLIVA', 'VIRGEN', 'EXTRA']):
        d.text(((w - d.textlength(line, font=f)) / 2, 40 + i * 44), line, font=f, fill=green)
    branch(d, (w / 2, 620), (w / 2 + 10, 250), 40, (110, 140, 90, 255), (60, 70, 40, 255), 70)
    d.rounded_rectangle([70, 660, 186, 900], radius=26, fill=(196, 176, 70, 255), outline=green, width=4)     # a bottle of it
    d.rectangle([106, 620, 150, 668], fill=(60, 80, 50, 255))
    f2 = font('georgia.ttf', 22)
    d.text(((w - d.textlength('de la casa', font=f2)) / 2, 930), 'de la casa', font=f2, fill=green)
    im.save(os.path.join(OUT, 'cartel.png'))


def tienda():
    w, h = 480, 400
    im = Image.new('RGBA', (w, h), COBALT + (255,))
    d = ImageDraw.Draw(im)
    d.rectangle([10, 10, w - 11, h - 11], outline=(255, 255, 255, 255), width=5)
    f = font('arialbd.ttf', 96)
    d.text(((w - d.textlength('TIENDA', font=f)) / 2, 50), 'TIENDA', font=f, fill=(255, 255, 255, 255))
    f2 = font('arialbd.ttf', 40)
    for i, line in enumerate(['venta directa', 'al público']):
        d.text(((w - d.textlength(line, font=f2)) / 2, 190 + i * 52), line, font=f2, fill=(255, 255, 255, 255))
    d.polygon([(190, 330), (290, 330), (290, 312), (330, 345), (290, 378), (290, 360), (190, 360)], fill=(255, 255, 255, 255))
    im.save(os.path.join(OUT, 'tienda.png'))


if __name__ == '__main__':
    logo(os.path.join(OUT, 'logo.png'), COBALT + (255,))
    logo(os.path.join(OUT, 'logo_gris.png'), SLATE + (255,))
    mural()
    emblema()
    cartel()
    tienda()
