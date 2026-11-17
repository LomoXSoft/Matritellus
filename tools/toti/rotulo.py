"""The signs of the Pizzería Toti (the user's name for the pizzeria of the Calle de Ramón y Cajal, 17 November 2026: "La
llamaremos Pizzeria Toti"), drawn here in the game's flat look -- nobody's photograph, name or logo: after Street View
2024 only in what goes where (a white box board with the name in big black letters and a little badge at each end; a
maroon awning whose valance carries the telephone numbers and the name; an oval lit sign of beer).

    python tools/toti/rotulo.py

Writes into godot/assets/toti/:
  rotulo.png      the white box board over the awning: TOTI, a round badge of our own at each end (a pizza)
  toldo.png       the awning's valance, maroon: TLF. and two telephone numbers (scribbles, as on every sign of the
                  game), PIZZERIA TOTI, the badge; its foot cut in scallops (transparent between them)
  cerveza.png     the oval lit sign of beer: a frothing glass, CERVEZA -- no brand
"""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'toti')
FONTS = os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts')
BOLD = os.path.join(FONTS, 'arialbd.ttf')
BLACK = os.path.join(FONTS, 'ariblk.ttf')
MAROON = (122, 26, 38)
rnd = random.Random(1711)


def scribble(d, x, y, w, h, col):
    """a telephone number nobody can ring"""
    pts = []
    for i in range(int(w / 7)):
        pts.append((x + i * 7, y + h / 2 + math.sin(i * 1.7) * h * 0.38 + rnd.uniform(-2, 2)))
    d.line(pts, fill=col, width=max(2, int(h / 7)))


def badge(d, cx, cy, r, ring=MAROON, paper=(255, 255, 255)):
    """our own badge: a pizza seen from above in a ring"""
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=ring)
    d.ellipse([cx - r * 0.84, cy - r * 0.84, cx + r * 0.84, cy + r * 0.84], fill=paper)
    p = r * 0.7
    d.ellipse([cx - p, cy - p, cx + p, cy + p], fill=(214, 150, 74))
    q = p * 0.84
    d.ellipse([cx - q, cy - q, cx + q, cy + q], fill=(236, 196, 92))
    for k in range(6):                          # the slices
        a = k * math.tau / 6
        d.line([(cx, cy), (cx + math.cos(a) * q, cy + math.sin(a) * q)], fill=(214, 150, 74), width=max(2, int(r / 18)))
    for i in range(7):
        a = rnd.uniform(0, math.tau); t = rnd.uniform(0.2, 0.75)
        x, y = cx + math.cos(a) * q * t, cy + math.sin(a) * q * t
        s = q * 0.13
        d.ellipse([x - s, y - s, x + s, y + s], fill=(186, 44, 36))
    for i in range(5):
        a = rnd.uniform(0, math.tau); t = rnd.uniform(0.2, 0.75)
        x, y = cx + math.cos(a) * q * t, cy + math.sin(a) * q * t
        s = q * 0.07
        d.ellipse([x - s, y - s, x + s, y + s], fill=(62, 120, 48))


def main():
    os.makedirs(OUT, exist_ok=True)
    # --- the box board: 2.45 m by 0.55 ---
    W, H = 1600, 360
    im = Image.new('RGB', (W, H), (250, 250, 248))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W - 1, H - 1], outline=(196, 196, 196), width=10)
    badge(d, 190, H / 2, 125)
    badge(d, W - 190, H / 2, 125)
    d.text((W / 2, H / 2 - 62), 'PIZZERIA', font=ImageFont.truetype(BOLD, 52), fill=MAROON, anchor='mm')
    d.text((W / 2, H / 2 + 36), 'TOTI', font=ImageFont.truetype(BLACK, 190), fill=(24, 24, 26), anchor='mm')
    im = im.filter(ImageFilter.GaussianBlur(0.5))
    im.save(os.path.join(OUT, 'rotulo.png'))
    # --- the awning's valance: 4.65 m by 0.3, scalloped at its foot ---
    W, H = 2480, 160
    im = Image.new('RGBA', (W, H), MAROON + (255,))
    d = ImageDraw.Draw(im)
    d.line([(0, 12), (W, 12)], fill=(240, 236, 228, 255), width=3)
    f = ImageFont.truetype(BOLD, 64)
    d.text((70, 66), 'TLF.', font=f, fill=(250, 248, 244, 255), anchor='lm')
    scribble(d, 230, 44, 360, 44, (250, 248, 244, 255))
    d.text((640, 66), '-', font=f, fill=(250, 248, 244, 255), anchor='mm')
    scribble(d, 690, 44, 360, 44, (250, 248, 244, 255))
    d.text((1120, 66), 'PIZZERIA  TOTI', font=ImageFont.truetype(BLACK, 76), fill=(250, 248, 244, 255), anchor='lm')
    badge(d, W - 150, 66, 56, ring=(250, 248, 244), paper=MAROON)
    # the scallops: half-circles hanging below a straight band, transparent between them
    band = 112
    step = 80
    cut = Image.new('L', (W, H), 255)
    cd = ImageDraw.Draw(cut)
    cd.rectangle([0, band, W, H], fill=0)
    for x in range(0, W + step, step):
        cd.pieslice([x - step / 2, band - step / 2 + 4, x + step / 2, band + step / 2 + 4], 0, 180, fill=255)
    im.putalpha(cut)
    im.save(os.path.join(OUT, 'toldo.png'))
    # --- the oval sign of beer: 0.55 m by 0.75 ---
    W, H = 440, 600
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([4, 4, W - 4, H - 4], fill=(222, 120, 30, 255))
    d.ellipse([30, 30, W - 30, H - 30], fill=(252, 250, 244, 255))
    gx, gy = W / 2, H * 0.47                    # a glass of beer, its froth over the rim
    d.polygon([(gx - 70, gy - 110), (gx + 70, gy - 110), (gx + 55, gy + 110), (gx - 55, gy + 110)], fill=(232, 168, 40, 255))
    for k in range(5):
        x = gx - 70 + k * 35
        d.ellipse([x - 26, gy - 150, x + 26, gy - 98], fill=(255, 255, 255, 255), outline=(220, 220, 214, 255), width=2)
    for k in range(6):                          # its bubbles
        bx = gx - 30 + rnd.uniform(0, 60)
        d.ellipse([bx, gy - 60 + k * 26, bx + 7, gy - 53 + k * 26], fill=(250, 214, 120, 255))
    d.text((W / 2, H * 0.8), 'CERVEZA', font=ImageFont.truetype(BLACK, 58), fill=(196, 40, 30, 255), anchor='mm')
    im.save(os.path.join(OUT, 'cerveza.png'))
    print('signs in', os.path.normpath(OUT))


if __name__ == '__main__':
    main()
