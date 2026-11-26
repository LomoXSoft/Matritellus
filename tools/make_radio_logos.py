"""Draws the logos of the car radio's stations in the style of the one the user made for Los 40 Secundarios: a rounded
square in the station's colour with a dark rim, the name in slanted cream lettering, radio waves in the top corner
and a little picture of what the station plays in the bottom one.

    python tools/make_radio_logos.py 2 3 4        (the numbers of the stations to draw; radio1's is the user's own)

It overwrites godot/radio/radioN/logo.png for the numbers given, and nothing else.
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', 'godot', 'radio')
S = 4                                   # drawn big, shrunk at the end
N = 256 * S
INK = (58, 38, 26, 255)
CREAM = (255, 244, 220, 255)

# number -> (colour, lines of the name as (text, size), picture)
LOGOS = {
    2: ((47, 143, 91), [('Traktor', 46), ('FM', 78)], 'tyre'),
    3: ((125, 63, 196), [('Onda', 50), ('Azafrán', 46)], 'saffron'),
    4: ((122, 84, 50), [('Radio', 46), ('Parroquia', 40)], 'bell'),
    5: ((190, 52, 46), [('Rap-A', 54), ('Polvo', 58)], 'mic'),
    7: ((29, 120, 166), [('Radio', 50), ('Patio', 58)], 'pot'),
}

def font(size):
    for name in ('ariblk.ttf', 'arialbd.ttf'):
        try:
            return ImageFont.truetype(os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts', name), size)
        except OSError:
            pass
    return ImageFont.load_default()

def lettering(lines):
    """the name, set tight, slanted like italics and tipped up a little to the right; each line as big as fits"""
    layer = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    y = 66 * S
    for text, size in lines:
        f = font(size * S)
        box = d.textbbox((0, 0), text, font=f)
        while box[2] - box[0] > 150 * S and size > 20:          # too wide for the badge: a size smaller
            size -= 2
            f = font(size * S)
            box = d.textbbox((0, 0), text, font=f)
        x = 44 * S - box[0]
        for k in (5, 4, 3):                                     # its shadow
            d.text((x + k * S * 0.6, y + (k + 1) * S * 0.6 - box[1]), text, font=f, fill=INK)
        d.text((x, y - box[1]), text, font=f, fill=CREAM, stroke_width=int(1.2 * S), stroke_fill=INK)
        y += (box[3] - box[1]) + 9 * S
    layer = layer.transform((N, N), Image.AFFINE, (1, 0.16, -0.16 * 110 * S, 0, 1, 0), Image.BICUBIC)       # italics
    return layer.rotate(6, resample=Image.BICUBIC, center=(128 * S, 128 * S))

def waves(d):
    cx, cy = 190 * S, 70 * S
    for k in range(3):
        r = (15 + k * 13) * S
        d.arc([cx - r, cy - r, cx + r, cy + r], 270, 20, fill=CREAM, width=7 * S)
    d.ellipse([cx - 7 * S, cy - 7 * S, cx + 7 * S, cy + 7 * S], fill=CREAM)

def picture(d, kind):
    cx, cy = 188 * S, 190 * S
    if kind == 'tyre':                     # a tractor's back wheel: fat lugs all round
        for k in range(12):
            a = k * math.tau / 12
            pts = [(cx + math.cos(a + da) * r * S, cy + math.sin(a + da) * r * S) for da, r in ((-0.16, 30), (0.16, 30), (0.1, 41), (-0.1, 41))]
            d.polygon(pts, fill=INK)
        d.ellipse([cx - 33 * S, cy - 33 * S, cx + 33 * S, cy + 33 * S], fill=INK)
        d.ellipse([cx - 22 * S, cy - 22 * S, cx + 22 * S, cy + 22 * S], fill=CREAM)
        d.ellipse([cx - 14 * S, cy - 14 * S, cx + 14 * S, cy + 14 * S], fill=INK)
        for k in range(5):
            a = k * math.tau / 5
            d.ellipse([cx + math.cos(a) * 8 * S - 2.5 * S, cy + math.sin(a) * 8 * S - 2.5 * S, cx + math.cos(a) * 8 * S + 2.5 * S, cy + math.sin(a) * 8 * S + 2.5 * S], fill=CREAM)
    elif kind == 'saffron':                # the flower: six lilac petals and the three red threads that are worth the money
        for k in range(6):
            a = k * math.tau / 6 - math.pi / 2
            tip = (cx + math.cos(a) * 40 * S, cy + math.sin(a) * 40 * S)
            l = (cx + math.cos(a - 0.5) * 21 * S, cy + math.sin(a - 0.5) * 21 * S)
            r = (cx + math.cos(a + 0.5) * 21 * S, cy + math.sin(a + 0.5) * 21 * S)
            d.polygon([(cx, cy), l, tip, r], fill=(216, 190, 255, 255) if k % 2 else (190, 150, 250, 255), outline=INK, width=3 * S)
        for k in range(3):
            a = -math.pi / 2 + (k - 1) * 0.75
            d.line([(cx, cy), (cx + math.cos(a) * 30 * S, cy + math.sin(a) * 30 * S)], fill=(226, 59, 50, 255), width=6 * S)
        d.ellipse([cx - 7 * S, cy - 7 * S, cx + 7 * S, cy + 7 * S], fill=(242, 194, 48, 255), outline=INK, width=2 * S)
    elif kind == 'mic':                    # a microphone, held at the angle of somebody who means it
        mic = Image.new('RGBA', (N, N), (0, 0, 0, 0))
        b = ImageDraw.Draw(mic)
        b.rounded_rectangle([cx - 9 * S, cy - 4 * S, cx + 9 * S, cy + 46 * S], radius=6 * S, fill=INK)
        b.ellipse([cx - 24 * S, cy - 46 * S, cx + 24 * S, cy + 2 * S], fill=CREAM, outline=INK, width=4 * S)
        for k in range(-2, 3):                       # the mesh of the head
            b.line([(cx + k * 9 * S, cy - 42 * S), (cx + k * 9 * S, cy - 2 * S)], fill=INK, width=2 * S)
            b.line([(cx - 22 * S, cy - 22 * S + k * 8 * S), (cx + 22 * S, cy - 22 * S + k * 8 * S)], fill=INK, width=2 * S)
        b.ellipse([cx - 24 * S, cy - 46 * S, cx + 24 * S, cy + 2 * S], outline=INK, width=4 * S)
        b.rectangle([cx - 12 * S, cy - 1 * S, cx + 12 * S, cy + 7 * S], fill=CREAM, outline=INK, width=3 * S)
        return mic.rotate(-28, resample=Image.BICUBIC, center=(cx, cy))
    elif kind == 'bell':                   # the bell of the parish, mid-swing, and its cross
        bell = Image.new('RGBA', (N, N), (0, 0, 0, 0))
        b = ImageDraw.Draw(bell)
        b.pieslice([cx - 30 * S, cy - 42 * S, cx + 30 * S, cy + 30 * S], 180, 360, fill=CREAM, outline=INK, width=4 * S)
        b.rectangle([cx - 30 * S, cy - 8 * S, cx + 30 * S, cy + 18 * S], fill=CREAM)
        b.line([(cx - 30 * S, cy - 8 * S), (cx - 30 * S, cy + 18 * S)], fill=INK, width=4 * S)
        b.line([(cx + 30 * S, cy - 8 * S), (cx + 30 * S, cy + 18 * S)], fill=INK, width=4 * S)
        b.rounded_rectangle([cx - 38 * S, cy + 16 * S, cx + 38 * S, cy + 28 * S], radius=6 * S, fill=CREAM, outline=INK, width=4 * S)
        b.ellipse([cx - 8 * S, cy + 26 * S, cx + 8 * S, cy + 42 * S], fill=INK)
        b.rectangle([cx - 3 * S, cy - 62 * S, cx + 3 * S, cy - 40 * S], fill=INK)
        b.rectangle([cx - 11 * S, cy - 56 * S, cx + 11 * S, cy - 50 * S], fill=INK)
        return bell.rotate(-14, resample=Image.BICUBIC, center=(cx, cy - 40 * S))
    elif kind == 'pot':                    # a terracotta patio flowerpot with red geraniums (añil y geranio manchego)
        pot = Image.new('RGBA', (N, N), (0, 0, 0, 0))
        b = ImageDraw.Draw(pot)
        # leafy greenery behind the flowers
        for dx, dy, rx, ry in ((-22, -16, 15, 11), (22, -16, 15, 11), (0, -24, 18, 13), (-14, -28, 13, 10), (14, -28, 13, 10)):
            b.ellipse([cx + (dx - rx) * S, cy + (dy - ry) * S, cx + (dx + rx) * S, cy + (dy + ry) * S],
                      fill=(56, 148, 72, 255), outline=INK, width=3 * S)
        # terracotta pot body & lip
        body = [(cx - 24 * S, cy - 4 * S), (cx + 24 * S, cy - 4 * S), (cx + 16 * S, cy + 36 * S), (cx - 16 * S, cy + 36 * S)]
        b.polygon(body, fill=(214, 104, 54, 255), outline=INK, width=4 * S)
        b.rounded_rectangle([cx - 30 * S, cy - 12 * S, cx + 30 * S, cy + 1 * S], radius=5 * S,
                            fill=(232, 122, 68, 255), outline=INK, width=4 * S)
        # red geranium blooms
        for fx, fy, r in ((-14, -24, 9), (14, -22, 9), (0, -34, 10)):
            for k in range(5):
                a = k * math.tau / 5 - math.pi / 2
                px, py = cx + (fx + math.cos(a) * r * 0.55) * S, cy + (fy + math.sin(a) * r * 0.55) * S
                pr = r * 0.55 * S
                b.ellipse([px - pr, py - pr, px + pr, py + pr], fill=(228, 56, 52, 255), outline=INK, width=2 * S)
            b.ellipse([cx + (fx - 3) * S, cy + (fy - 3) * S, cx + (fx + 3) * S, cy + (fy + 3) * S],
                      fill=(255, 224, 96, 255), outline=INK, width=2 * S)
        return pot.rotate(-8, resample=Image.BICUBIC, center=(cx, cy))
    return None

def draw(n):
    colour, lines, kind = LOGOS[n]
    im = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([10 * S, 10 * S, 246 * S, 246 * S], radius=40 * S, fill=INK)
    d.rounded_rectangle([19 * S, 19 * S, 237 * S, 237 * S], radius=32 * S, fill=tuple(min(255, int(c * 1.18)) for c in colour) + (255,))
    d.rounded_rectangle([23 * S, 23 * S, 233 * S, 233 * S], radius=28 * S, fill=colour + (255,))
    waves(d)
    extra = picture(d, kind)
    if extra is not None:
        im.alpha_composite(extra)
    im.alpha_composite(lettering(lines))
    out = os.path.join(ROOT, 'radio%d' % n, 'logo.png')
    im.resize((256, 256), Image.LANCZOS).save(out)
    print('radio%d' % n, lines[0][0], lines[1][0], '->', os.path.relpath(out, os.path.join(HERE, '..')))

if __name__ == '__main__':
    for arg in sys.argv[1:]:
        draw(int(arg))
