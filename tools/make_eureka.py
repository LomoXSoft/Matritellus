"""The star that pops up over somebody's head when an idea strikes them (recress.gd eureka):
godot/assets/recress/eureka.png, 256 x 256 with a transparent background.

    python tools/make_eureka.py

A fat five-pointed star, yellow with a dark rim and a light glint, and three short strokes flying off one side of it
-- the comic-strip sign for "something has caught their eye". Drawn here from shapes (the user pointed at what Animal
Crossing does; nothing of that game is used).
"""
import math, os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), 'godot', 'assets', 'recress', 'eureka.png')
S = 4                       # drawn four times bigger, for smooth edges
N = 256 * S
YELLOW = (255, 214, 58, 255)
DARK = (74, 46, 12, 255)
GLINT = (255, 246, 196, 255)


def star(cx, cy, r_out, r_in, turn=-90.0):
    pts = []
    for i in range(10):
        r = r_out if i % 2 == 0 else r_in
        a = math.radians(turn + i * 36.0)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def stroke(d, x0, y0, x1, y1, w):
    d.line((x0, y0, x1, y1), fill=DARK, width=int(w + 10 * S))
    for p in [(x0, y0), (x1, y1)]:
        r = (w + 10 * S) / 2
        d.ellipse((p[0] - r, p[1] - r, p[0] + r, p[1] + r), fill=DARK)
    d.line((x0, y0, x1, y1), fill=YELLOW, width=int(w))
    for p in [(x0, y0), (x1, y1)]:
        r = w / 2
        d.ellipse((p[0] - r, p[1] - r, p[0] + r, p[1] + r), fill=YELLOW)


img = Image.new('RGBA', (N, N), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
cx, cy = 96 * S, 158 * S
d.polygon(star(cx, cy, 84 * S, 42 * S), fill=DARK)                 # the rim
d.polygon(star(cx, cy + 2 * S, 71 * S, 34 * S), fill=YELLOW)
d.polygon(star(cx - 13 * S, cy - 16 * S, 20 * S, 10 * S, -80.0), fill=GLINT)      # a glint on the top left arm
for k, (a, length) in enumerate([(-58.0, 40), (-28.0, 34), (2.0, 28)]):     # three strokes flying off to the right
    ang = math.radians(a)
    r0 = 88 * S
    x0, y0 = cx + r0 * math.cos(ang) + 18 * S, cy + r0 * math.sin(ang) - 6 * S
    x1, y1 = x0 + length * S * math.cos(ang), y0 + length * S * math.sin(ang)
    stroke(d, x0, y0, x1, y1, 16 * S)
img = img.resize((256, 256), Image.LANCZOS)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
img.save(OUT)
print(OUT)
