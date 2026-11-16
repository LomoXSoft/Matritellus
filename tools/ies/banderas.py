"""The three flags behind the way in of the IES Valdeacero (the user, 17 November 2026: "las tres banderas (Castilla
la mancha / España / Europa)"), drawn here in the game's flat look.

    python tools/ies/banderas.py

Writes into godot/assets/ies/:
  bandera_region.png   the region's: divided upright, crimson at the hoist with a yellow castle, white at the fly
  bandera_espana.png   red, yellow, red (1:2:1), plain -- as every flag of the game (the barracks', the roundabout's)
  bandera_europa.png   blue, its ring of twelve gold stars
"""
import math, os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'ies')
W, H = 600, 400


def region():
    im = Image.new('RGB', (W, H), (250, 250, 248))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W // 2, H], fill=(166, 22, 56))
    # the castle: a body, three towers with merlons, a door and windows in the crimson
    gold = (246, 196, 40)
    cx, base = W // 4, 300
    d.rectangle([cx - 95, base - 120, cx + 95, base], fill=gold)
    for tx in (cx - 95, cx - 22, cx + 51):
        d.rectangle([tx, base - 185, tx + 44, base - 110], fill=gold)
        for m in range(3):
            d.rectangle([tx + m * 16, base - 205, tx + m * 16 + 12, base - 185], fill=gold)
    d.chord([cx - 24, base - 70, cx + 24, base + 26], 180, 360, fill=(166, 22, 56))
    d.rectangle([cx - 24, base - 22, cx + 24, base], fill=(166, 22, 56))
    for tx in (cx - 81, cx + 65):
        d.rectangle([tx, base - 160, tx + 12, base - 135], fill=(166, 22, 56))
    for m in range(9):
        d.line([(cx - 95, base - 120 + m * 13), (cx + 95, base - 120 + m * 13)], fill=(214, 160, 30), width=1)
    im.save(os.path.join(OUT, 'bandera_region.png'))


def spain():
    im = Image.new('RGB', (W, H), (198, 11, 30))
    ImageDraw.Draw(im).rectangle([0, H // 4, W, H * 3 // 4], fill=(255, 196, 0))
    im.save(os.path.join(OUT, 'bandera_espana.png'))


def europe():
    im = Image.new('RGB', (W, H), (0, 51, 153))
    d = ImageDraw.Draw(im)
    r_ring, r_star = H / 3.0, H / 18.0
    for k in range(12):
        a = math.tau * k / 12.0
        cx, cy = W / 2 + math.sin(a) * r_ring, H / 2 - math.cos(a) * r_ring
        pts = []
        for j in range(10):
            b = math.pi * j / 5.0
            r = r_star if j % 2 == 0 else r_star * 0.4
            pts.append((cx + math.sin(b) * r, cy - math.cos(b) * r))
        d.polygon(pts, fill=(255, 204, 0))
    im.save(os.path.join(OUT, 'bandera_europa.png'))


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    region()
    spain()
    europe()
    print('written to', os.path.abspath(OUT))
