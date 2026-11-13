"""Draws the sign of "df Mecánica", the made-up garage on the Calle del Palo: a tyre seen three-quarters on, a red d and
a dark f leaning on it, MECANICA underneath. Our own drawing, in the manner of a thousand garage signs.

    python tools/make_df.py   ->   godot/assets/df_mecanica.png  (1024 x 400, white board)
"""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'godot', 'assets', 'df_mecanica.png')
S = 3                                   # drawn big, then shrunk, for clean edges
W, H = 1024 * S, 400 * S
RED, DARK, WHITE = (213, 32, 42), (38, 38, 42), (250, 250, 248)

def font(name, size):
    for path in (os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts', name), name):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            pass
    return ImageFont.load_default()

def main():
    im = Image.new('RGB', (W, H), WHITE)
    d = ImageDraw.Draw(im)
    # the tyre: a fat dark ellipse, the tread as pale notches round its left edge, the rim as a paler ellipse inside
    cx, cy, rx, ry = 215 * S, 200 * S, 150 * S, 178 * S
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=DARK)
    for k in range(-9, 10):                                   # tread blocks: two staggered rows down the left side
        a = math.pi + k * 0.15
        for row, (r0, r1) in enumerate(((0.80, 0.97), (0.60, 0.77))):
            b = a + (0.075 if row else 0.0)
            pts = []
            for aa, rr in ((b - 0.05, r0), (b + 0.05, r0), (b + 0.05, r1), (b - 0.05, r1)):
                pts.append((cx + math.cos(aa) * rx * rr, cy + math.sin(aa) * ry * rr))
            d.polygon(pts, fill=WHITE)
    d.ellipse([cx - rx * 0.36, cy - ry * 0.74, cx + rx * 0.92, cy + ry * 0.74], fill=WHITE)      # the hole of the wheel
    d.ellipse([cx + rx * 0.02, cy - ry * 0.52, cx + rx * 0.80, cy + ry * 0.52], fill=DARK)
    d.ellipse([cx + rx * 0.12, cy - ry * 0.42, cx + rx * 0.86, cy + ry * 0.42], fill=WHITE)
    d.rectangle([cx + rx * 0.35, 0, W, H], fill=WHITE)                                           # the letters cut it off
    d.ellipse([cx - rx * 0.36, cy - ry * 0.74, cx + rx * 0.35, cy + ry * 0.74], outline=DARK, width=6 * S)
    d.rectangle([cx + rx * 0.2, 0, W, H], fill=WHITE)
    # the letters
    big = font('ariblk.ttf', 250 * S)
    d.text((250 * S, 20 * S), 'd', font=big, fill=RED)
    d.text((412 * S, 20 * S), 'f', font=big, fill=DARK)
    word = font('arialbd.ttf', 78 * S)
    d.text((562 * S, 108 * S), 'MEC\u00c1NICA', font=word, fill=RED)
    small = font('arial.ttf', 40 * S)
    d.text((566 * S, 214 * S), 'chapa \u00b7 lunas \u00b7 ruedas', font=small, fill=DARK)
    d.rectangle([250 * S, 322 * S, 990 * S, 336 * S], fill=RED)
    im = im.resize((1024, 400), Image.LANCZOS)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    im.save(OUT)
    print('df_mecanica.png', im.size)

if __name__ == '__main__':
    main()
