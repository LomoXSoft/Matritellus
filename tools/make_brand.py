"""Draws the mark of "Ahorros Rurales", the made-up savings bank of the game: a piggy bank with an ear of wheat
growing out of the coin slot. White on transparent, so the game can tint it (yellow on green, green on yellow...).

    python tools/make_brand.py        ->  godot/assets/ahorros_rurales.png  (+ a preview next to this script's output)
"""
import math, os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'godot', 'assets', 'ahorros_rurales.png')
N = 2048          # drawn big, shrunk for smooth edges
W = (255, 255, 255, 255)
HOLE = (255, 255, 255, 0)

img = Image.new('RGBA', (N, N), HOLE)
d = ImageDraw.Draw(img)
def px(v): return v * N
def ell(cx, cy, rx, ry, fill=W, turn=0.0):
    pts = []
    for k in range(48):
        a = k / 48 * math.tau
        x, y = math.cos(a) * rx, math.sin(a) * ry
        pts.append((px(cx + x * math.cos(turn) - y * math.sin(turn)), px(cy + x * math.sin(turn) + y * math.cos(turn))))
    d.polygon(pts, fill=fill)
def rect(x0, y0, x1, y1, fill=W, r=0.0):
    d.rounded_rectangle([px(x0), px(y0), px(x1), px(y1)], radius=px(r), fill=fill)

# the pig
ell(0.45, 0.715, 0.30, 0.195)                       # body
ell(0.735, 0.70, 0.135, 0.135)                      # head
ell(0.875, 0.725, 0.07, 0.06)                       # snout
d.polygon([(px(0.64), px(0.60)), (px(0.79), px(0.60)), (px(0.725), px(0.445))], fill=W)     # ear
rect(0.24, 0.84, 0.33, 0.965, r=0.03)               # legs
rect(0.56, 0.84, 0.65, 0.965, r=0.03)
ell(0.118, 0.635, 0.055, 0.055); ell(0.118, 0.635, 0.03, 0.03, HOLE)                        # curly tail
rect(0.118, 0.66, 0.175, 0.70)
ell(0.775, 0.665, 0.021, 0.021, HOLE)               # eye
ell(0.895, 0.725, 0.013, 0.02, HOLE)                # nostril
rect(0.335, 0.558, 0.565, 0.584, HOLE, r=0.012)     # the coin slot

# the ear of wheat that grows out of it
STEM = 0.45
rect(STEM - 0.012, 0.13, STEM + 0.012, 0.60)
for i, y in enumerate([0.445, 0.365, 0.285, 0.205]):
    for side in (-1, 1):
        ell(STEM + side * 0.058, y - 0.02, 0.03, 0.066, turn=side * 0.6)
ell(STEM, 0.095, 0.03, 0.07)

img = img.resize((512, 512), Image.LANCZOS)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
img.save(OUT)

# a preview the way it is used: yellow on green
prev = Image.new('RGBA', (512, 512), (31, 138, 85, 255))
yellow = Image.new('RGBA', (512, 512), (242, 194, 48, 255))
prev.paste(yellow, (0, 0), img)
prev.save(os.path.join(HERE, 'ahorros_rurales_preview.png'))
print('wrote', os.path.normpath(OUT))
