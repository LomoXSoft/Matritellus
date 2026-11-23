"""tools/iconos_mapa.py OUT.png: preview of the map icons for the clothes, accessories and shoe shops: the gold coin of the peseta with a glyph
in ink on it: a shirt (clothes), a ring (accessories), a shoe (shoes). The shapes are in units of the coin's radius (y down), as minimap.gd will draw them."""
import math, sys
from PIL import Image, ImageDraw

INK = (0x3a, 0x2a, 0x12)
RIM = (0xc9, 0x94, 0x19)
GOLD = (0xf2, 0xc2, 0x30)
RING = (0xb0, 0x7d, 0x12)
MAP = (0xe9, 0xd9, 0xa6)

SHIRT = [(-0.17, -0.52), (-0.40, -0.44), (-0.66, -0.16), (-0.48, 0.0), (-0.33, -0.12), (-0.33, 0.52), (0.33, 0.52),
         (0.33, -0.12), (0.48, 0.0), (0.66, -0.16), (0.40, -0.44), (0.17, -0.52), (0.09, -0.40), (0.0, -0.37),
         (-0.09, -0.40)]
GEM = [(-0.17, -0.62), (0.17, -0.62), (0.33, -0.46), (0.0, -0.12), (-0.33, -0.46)]
SHOE = [(-0.62, -0.28), (-0.32, -0.20), (-0.06, -0.34), (0.20, -0.20), (0.44, -0.08), (0.60, 0.05), (0.64, 0.19), (0.60, 0.28),
        (0.0, 0.28), (-0.20, 0.17), (-0.30, 0.17), (-0.30, 0.34), (-0.60, 0.34), (-0.64, 0.06)]

def coin(d, at, r):
    x, y = at
    def circ(rr, col):
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=col)
    circ(r + 1.2 * S, INK)
    circ(r, RIM)
    circ(r * 0.8, GOLD)
    w = max(1, int(r * 0.08))
    d.ellipse([x - r * 0.8, y - r * 0.8, x + r * 0.8, y + r * 0.8], outline=RING, width=w)

def poly(d, at, r, pts, col=INK):
    d.polygon([(at[0] + px * r, at[1] + py * r) for px, py in pts], fill=col)

def shirt(d, at, r):
    poly(d, at, r, SHIRT)

def ring(d, at, r):
    x, y = at
    w = max(1, int(round(r * 0.17)))            # the band, an oval: seen a little from above
    rx, ry, cy = r * 0.44, r * 0.30, y + 0.2 * r
    d.ellipse([x - rx, cy - ry, x + rx, cy + ry], outline=INK, width=w)
    poly(d, at, r, GEM)                         # the stone sat on it, cut
    d.line([(x - 0.33 * r, y - 0.46 * r), (x + 0.33 * r, y - 0.46 * r)], fill=GOLD, width=max(1, int(round(r * 0.06))))

def shoe(d, at, r):
    x, y = at
    poly(d, at, r, SHOE)                        # an ordinary shoe, the toe to the right, its heel apart from the sole
    d.line([(x + 0.0 * r, y + 0.19 * r), (x + 0.58 * r, y + 0.19 * r)], fill=GOLD, width=max(1, int(round(r * 0.07))))      # the welt

def peseta(d, at, r):                           # (the one there is now, for comparison)
    x, y = at
    w = max(1, int(r * 0.17))
    x0 = x - r * 0.28
    top, bot = y - r * 0.5, y + r * 0.52
    d.line([(x0, top), (x0, bot)], fill=INK, width=w)
    bc = (x0 + r * 0.16, y - r * 0.22)
    br = r * 0.28
    d.arc([bc[0] - br, bc[1] - br, bc[0] + br, bc[1] + br], -90, 90, fill=INK, width=w)
    d.line([(x0, top), (bc[0], top)], fill=INK, width=w)
    d.line([(x0, bc[1] + br), (bc[0], bc[1] + br)], fill=INK, width=w)
    for yy in (y - r * 0.3, y - r * 0.12):
        d.line([(x - r * 0.52, yy), (x + r * 0.42, yy)], fill=INK, width=max(1, int(w * 0.7)))

out = sys.argv[1]
glyphs = [peseta, shirt, ring, shoe]
# big (8x) and at the map's size (radius 9 px), side by side on the map's colour
S = 8
big = Image.new("RGB", (len(glyphs) * 200, 200), MAP)
d = ImageDraw.Draw(big)
for i, g in enumerate(glyphs):
    coin(d, (100 + i * 200, 100), 9 * S)
    g(d, (100 + i * 200, 100), 9 * S)
S = 4
small = Image.new("RGB", (len(glyphs) * 30 * S, 30 * S), MAP)
d = ImageDraw.Draw(small)
for i, g in enumerate(glyphs):
    coin(d, ((15 + i * 30) * S, 15 * S), 9 * S)
    g(d, ((15 + i * 30) * S, 15 * S), 9 * S)
small = small.resize((len(glyphs) * 30, 30), Image.LANCZOS).resize((len(glyphs) * 120, 120), Image.NEAREST)
sheet = Image.new("RGB", (big.width, big.height + small.height + 10), MAP)
sheet.paste(big, (0, 0))
sheet.paste(small, ((big.width - small.width) // 2, big.height + 5))
sheet.save(out)
