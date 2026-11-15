"""Paints the mural of the end wall of the nursery school of the Calle del Palo: the doves of peace over a rainbow of
broad bands, with big round flowers along the bottom (the user, 15 November 2026: "el mural de esta zona lo reharía como
lo que es. Una paloma de la paz con un arcoíris de fondo").

    python tools/calasanz/mural.py [OUT.png]          (default: godot/assets/calasanz/mural_palomas.png)

Redrawn by hand, shape by shape, over Street View's pictures of October 2019 and November 2024 flattened to the wall
(panoramas yXY6820rO1EBTA3kOCnI-A and rz3QoN2xyshlk5J1QCwRXQ: from 2019 on the prefab cabin that hid it is gone), with
the colours of May 2009, when the paint was fresh: there was a yellow panel behind the wing, which has faded to white.
Every place is (u, t): across the wall from its street corner, and down from the brick course; the wall is 5.88 m by
3.12 m, so a pixel is as wide as it is tall and a circle here is a circle on the wall.
"""
import math, os, sys
from PIL import Image, ImageDraw

W, H, SS = 1536, 816, 3
RED, GREEN, DARK, TEAL = (217, 56, 46), (42, 150, 80), (31, 122, 68), (31, 143, 134)
BLUE, PALE, YELLOW, CREAM = (42, 98, 200), (85, 134, 220), (240, 212, 86), (246, 237, 200)
WHITE, LINE, GREY = (253, 252, 248), (28, 42, 68), (138, 143, 154)
PEN = 0.0021                    # the outline round every shape: about 1.2 cm on the wall

im = Image.new('RGB', (W * SS, H * SS), CREAM)
d = ImageDraw.Draw(im)


def px(p):
    return (p[0] * W * SS, p[1] * H * SS)


def _run(pts, closed, steps=12):
    out = []
    n = len(pts)
    for i in range(n if closed else n - 1):
        p0 = pts[(i - 1) % n] if closed or i > 0 else pts[0]
        p1, p2 = pts[i % n], pts[(i + 1) % n]
        p3 = pts[(i + 2) % n] if closed or i + 2 < n else pts[-1]
        for s in range(steps):
            t = s / steps
            out.append(tuple(0.5 * ((2 * p1[k]) + (-p0[k] + p2[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t * t
                                    + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t ** 3) for k in (0, 1)))
    if not closed:
        out.append(pts[-1])
    return out


def curve(pts, closed=True):
    """A smooth line through the points (Catmull-Rom). A point given twice running is a corner: the line is smooth from
    one corner to the next and turns sharply at each."""
    clean, corner = [], []
    for p in pts:
        if clean and p == clean[-1]:
            corner[-1] = True
            continue
        clean.append(p); corner.append(False)
    if not closed:
        return _run(clean, False)
    if not any(corner):
        return _run(clean, True)
    k = corner.index(True)
    clean, corner = clean[k:] + clean[:k], corner[k:] + corner[:k]
    out, run = [], [clean[0]]
    for i in range(1, len(clean) + 1):
        p = clean[i % len(clean)]
        run.append(p)
        if corner[i % len(clean)]:
            out += _run(run, False)[:-1]
            run = [p]
    return out


def pen(pts, colour=LINE, width=PEN, closed=True):
    w = max(2, int(round(width * W * SS)))
    q = [px(p) for p in pts]
    if closed:
        q = q + q[:2]
    d.line(q, fill=colour, width=w, joint='curve')


def shape(pts, fill, smooth=True, line=True):
    q = curve(pts) if smooth else pts
    d.polygon([px(p) for p in q], fill=fill)
    if line:
        pen(q)


def disc(c, r, fill, line=True, squash=1.0):
    """A circle of radius r (in widths of the wall); squash: how much taller than wide."""
    q = [(c[0] + r * math.cos(a), c[1] + r * squash * math.sin(a) * W / H) for a in [math.tau * i / 48 for i in range(48)]]
    shape(q, fill, False, line)


def spokes(c, r0, r1, a0, a1, n, dot=0.0045):
    for i in range(n):
        a = math.radians(a0 + (a1 - a0) * i / (n - 1))
        p = (c[0] + r0 * math.cos(a), c[1] - r0 * math.sin(a) * W / H)
        q = (c[0] + r1 * math.cos(a), c[1] - r1 * math.sin(a) * W / H)
        pen([p, q], LINE, 0.0016, False)
        disc(q, dot, LINE, False)


def stroke(pts, colour, width):
    q = curve(pts, False)
    pen(q, colour, width, False)
    for p in (q[0], q[-1]):
        disc(p, width / 2.0, colour, False)


# ---------------- the rainbow: broad bands, each of its own colour ----------------
shape([(0.13, -0.02), (0.37, -0.02), (0.37, 0.25), (0.13, 0.25)], GREEN, False)
shape([(-0.02, -0.02), (0.176, -0.02), (0.166, 0.08), (0.136, 0.17), (0.10, 0.238), (0.05, 0.215), (-0.02, 0.2)], RED)
shape([(0.357, -0.02), (0.70, -0.02), (0.70, 0.2), (0.357, 0.2)], PALE, False)
shape([(0.66, -0.02), (0.90, -0.02), (0.90, 0.42), (0.66, 0.42)], YELLOW, False)
shape([(0.78, 0.24), (1.02, 0.24), (1.02, 0.56), (0.9, 0.5), (0.78, 0.47)], RED, False)
shape([(0.845, -0.03), (0.845, -0.03), (1.03, -0.03), (1.03, -0.03), (1.03, 0.318), (1.03, 0.318), (0.95, 0.305), (0.897, 0.268), (0.862, 0.2), (0.846, 0.1)], GREEN)
shape([(0.325, 0.112), (0.325, 0.112), (0.52, 0.114), (0.565, 0.14), (0.572, 0.25), (0.545, 0.36), (0.50, 0.375), (0.43, 0.3), (0.325, 0.278), (0.325, 0.278)], RED)
shape([(0.095, 0.245), (0.14, 0.186), (0.2, 0.146), (0.27, 0.12), (0.325, 0.112), (0.325, 0.112), (0.325, 0.278), (0.325, 0.278), (0.27, 0.292), (0.21, 0.314), (0.16, 0.338), (0.16, 0.338)], CREAM)
shape([(0.16, 0.338), (0.16, 0.338), (0.325, 0.278), (0.425, 0.27), (0.425, 0.27), (0.43, 0.33), (0.385, 0.44), (0.3, 0.535), (0.3, 0.535), (0.24, 0.44)], TEAL)
shape([(-0.03, 0.205), (0.04, 0.2), (0.095, 0.238), (0.14, 0.3), (0.166, 0.38), (0.162, 0.46), (0.125, 0.5), (0.105, 0.6), (0.085, 0.7), (0.03, 0.78), (-0.03, 0.8)], BLUE)
disc((0.445, 0.495), 0.098, BLUE)
shape([(0.555, 0.6), (0.62, 0.552), (0.72, 0.46), (0.8, 0.41), (0.9, 0.47), (1.03, 0.532), (1.03, 0.532), (1.03, 1.03), (1.03, 1.03), (0.71, 1.03), (0.71, 1.03), (0.69, 0.85), (0.63, 0.7), (0.57, 0.625)], BLUE)
shape([(0.955, 0.55), (1.03, 0.56), (1.03, 0.9), (0.95, 0.9), (0.985, 0.72)], CREAM)
shape([(0.9, 0.935), (0.96, 0.872), (1.03, 0.85), (1.03, 1.03), (0.88, 1.03)], RED)
shape([(-0.03, 0.8), (0.03, 0.762), (0.07, 0.736), (0.15, 0.75), (0.25, 0.766), (0.36, 0.76), (0.43, 0.735), (0.476, 0.724), (0.49, 0.8), (0.486, 1.03), (0.486, 1.03), (-0.03, 1.03), (-0.03, 1.03)], GREEN)
shape([(0.115, 0.965), (0.16, 0.922), (0.215, 0.95), (0.236, 1.03), (0.11, 1.03)], CREAM)
shape([(0.585, 1.03), (0.6, 0.93), (0.635, 0.892), (0.665, 0.93), (0.672, 1.03)], DARK)

# ---------------- the two doves ----------------
# the one at rest, to the left, looking right
shape([(0.372, 0.368), (0.395, 0.375), (0.411, 0.396), (0.429, 0.416), (0.429, 0.416), (0.405, 0.432), (0.39, 0.47), (0.388, 0.54), (0.392, 0.62), (0.375, 0.7),
       (0.33, 0.75), (0.26, 0.763), (0.18, 0.752), (0.1, 0.746), (0.062, 0.712), (0.062, 0.712), (0.086, 0.676), (0.068, 0.636), (0.068, 0.636), (0.093, 0.6),
       (0.078, 0.56), (0.078, 0.56), (0.106, 0.526), (0.1, 0.486), (0.1, 0.486), (0.136, 0.46), (0.151, 0.4), (0.158, 0.34), (0.158, 0.34), (0.2, 0.362),
       (0.25, 0.432), (0.3, 0.527), (0.3, 0.527), (0.336, 0.47), (0.353, 0.41)], WHITE)
stroke([(0.166, 0.45), (0.19, 0.515), (0.177, 0.56), (0.2, 0.635)], GREY, 0.0018)
stroke([(0.21, 0.47), (0.232, 0.53), (0.222, 0.58), (0.24, 0.64)], GREY, 0.0018)
disc((0.386, 0.398), 0.0042, LINE, False)
# the one in flight, to the right, looking left, its wing up into the yellow
shape([(0.435, 0.212), (0.458, 0.222), (0.478, 0.255), (0.492, 0.31), (0.508, 0.354), (0.508, 0.354), (0.531, 0.31), (0.548, 0.22), (0.566, 0.146), (0.61, 0.105),
       (0.662, 0.088), (0.692, 0.052), (0.692, 0.052), (0.703, 0.1), (0.703, 0.1), (0.733, 0.082), (0.733, 0.082), (0.738, 0.136), (0.738, 0.136), (0.768, 0.122),
       (0.768, 0.122), (0.768, 0.176), (0.768, 0.176), (0.798, 0.168), (0.798, 0.168), (0.793, 0.226), (0.793, 0.226), (0.82, 0.224), (0.82, 0.224), (0.808, 0.286),
       (0.845, 0.266), (0.888, 0.272), (0.888, 0.272), (0.85, 0.345), (0.812, 0.406), (0.812, 0.406), (0.795, 0.44), (0.76, 0.457), (0.72, 0.468), (0.67, 0.505),
       (0.63, 0.555), (0.585, 0.58), (0.53, 0.578), (0.485, 0.545), (0.462, 0.48), (0.45, 0.4), (0.432, 0.33), (0.415, 0.296), (0.393, 0.277), (0.393, 0.277),
       (0.412, 0.25), (0.421, 0.226)], WHITE)
for a, b in (((0.703, 0.1), (0.655, 0.17)), ((0.738, 0.136), (0.688, 0.21)), ((0.768, 0.176), (0.716, 0.255)), ((0.793, 0.226), (0.745, 0.3))):
    stroke([a, ((a[0] + b[0]) / 2 - 0.006, (a[1] + b[1]) / 2 - 0.004), b], GREY, 0.0018)
stroke([(0.628, 0.15), (0.607, 0.25), (0.612, 0.35), (0.64, 0.43)], GREY, 0.0018)
disc((0.427, 0.248), 0.0042, LINE, False)

# ---------------- the flowers, from the street corner to the back ----------------
# a red wheel on a red stem
stroke([(0.088, 0.93), (0.096, 0.97), (0.108, 1.03)], LINE, 0.016)
stroke([(0.088, 0.93), (0.096, 0.97), (0.108, 1.03)], RED, 0.0118)
disc((0.085, 0.862), 0.052, RED)
spokes((0.085, 0.862), 0.02, 0.039, -20, 200, 9)
disc((0.085, 0.866), 0.015, WHITE)
# a white one with a blue drop for a heart, on a blue stem
disc((0.197, 0.868), 0.046, WHITE)
spokes((0.197, 0.872), 0.02, 0.036, 5, 175, 8)
shape([(0.197, 0.862), (0.214, 0.885), (0.217, 0.93), (0.228, 0.98), (0.243, 1.04), (0.222, 1.04), (0.205, 0.985), (0.186, 0.935), (0.181, 0.89)], BLUE)
# a white daisy on a red wheel, on a white stem
stroke([(0.305, 0.93), (0.305, 1.03)], LINE, 0.0125)
stroke([(0.305, 0.93), (0.305, 1.03)], WHITE, 0.0085)
disc((0.305, 0.845), 0.066, RED)
for i in range(8):
    a = math.tau * (i + 0.5) / 8
    disc((0.305 + 0.036 * math.cos(a), 0.845 + 0.036 * math.sin(a) * W / H), 0.0185, WHITE)
disc((0.305, 0.845), 0.033, WHITE, False)
for i in range(8):
    a = math.tau * (i + 0.5) / 8
    disc((0.305 + 0.047 * math.cos(a), 0.845 + 0.047 * math.sin(a) * W / H), 0.0036, LINE, False)
disc((0.305, 0.845), 0.022, CREAM)
disc((0.305, 0.845), 0.014, GREY)
disc((0.305, 0.845), 0.0105, CREAM, False)
disc((0.305, 0.845), 0.0068, BLUE, False)
# a blue one with a red tulip inside, on a red stem
stroke([(0.469, 0.87), (0.471, 0.95), (0.477, 1.03)], LINE, 0.0155)
stroke([(0.469, 0.87), (0.471, 0.95), (0.477, 1.03)], RED, 0.0115)
disc((0.468, 0.8), 0.055, PALE)
spokes((0.468, 0.822), 0.02, 0.041, 15, 165, 7)
shape([(0.45, 0.83), (0.468, 0.822), (0.486, 0.83), (0.484, 0.875), (0.468, 0.9), (0.452, 0.875)], RED)
# the big red daisy with its green heart and its white keyhole
stroke([(0.675, 0.75), (0.675, 1.03)], LINE, 0.0185)
for i in range(18):
    a = math.tau * (i + 0.5) / 18
    c, s = math.cos(a), math.sin(a)
    petal = []
    for k in range(20):
        b = math.tau * k / 20
        x, y = 0.087 + 0.04 * math.cos(b), 0.0165 * math.sin(b)
        petal.append((0.675 + x * c - y * s, 0.742 + (x * s + y * c) * W / H))
    shape(petal, RED, False)
disc((0.675, 0.742), 0.066, DARK)
stroke([(0.675, 0.75), (0.675, 1.03)], LINE, 0.0185)
stroke([(0.675, 0.75), (0.675, 1.03)], WHITE, 0.0145)
disc((0.675, 0.735), 0.027, WHITE)
stroke([(0.675, 0.755), (0.675, 0.83)], WHITE, 0.0145)
# the green one ringed with white petals, on its green stem
shape([(0.862, 0.86), (0.905, 0.86), (0.9, 0.95), (0.905, 1.04), (0.855, 1.04), (0.862, 0.95)], DARK, False)
disc((0.885, 0.7), 0.102, DARK)
for i in range(14):
    a = math.tau * i / 14
    c, s = math.cos(a), math.sin(a)
    petal = []
    for k in range(16):
        b = math.tau * k / 16
        x, y = 0.076 + 0.0155 * math.cos(b), 0.0125 * math.sin(b)
        petal.append((0.885 + x * c - y * s, 0.7 + (x * s + y * c) * W / H))
    shape(petal, WHITE, False)
    disc((0.885 + 0.083 * c, 0.7 + 0.083 * s * W / H), 0.0034, LINE, False)
disc((0.885, 0.7), 0.054, PALE)
disc((0.885, 0.7), 0.041, CREAM)
# a few little white ones at the foot of the wall
for c in ((0.752, 0.962), (0.8, 0.975), (0.846, 0.968)):
    for i in range(5):
        a = math.tau * i / 5
        disc((c[0] + 0.009 * math.cos(a), c[1] + 0.009 * math.sin(a) * W / H), 0.0065, WHITE, False)
    disc(c, 0.004, YELLOW, False)

out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'godot', 'assets', 'calasanz', 'mural_palomas.png')
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
im = im.resize((W, H), Image.LANCZOS)
im.save(out, optimize=True)
print(out, im.size)
