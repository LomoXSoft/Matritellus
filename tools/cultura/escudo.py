"""The coat of arms of stone over the doorway of the Casa Grande, drawn by hand as a carved relief (no photograph in it):
a height field drawn with PIL, then the picture of it lit from above and on the left, and its normal map, so that the
sun of the game moves over the carving.

    python tools/cultura/escudo.py      -> godot/assets/cultura/escudo.png, escudo_n.png (then the Godot import)

Drawn after the town hall's photograph of it (madridejos.es, "Casa Grande", DSC_0321; the user sent the page on
17-11-2026), measured in centimetres on it: the field inside the moulded frame is 71 x 91 cm (cultura.gd builds the
frame round it). A helmet with its plumes over a draped mantle, acanthus scrolls all round, a shell under the point;
the shield (round foot, Spanish fashion) quartered, inside a bordure with saltires:
  1  roundels in columns either side of a staff, two bigger ones on top;
  2  a tower with an eagle on it, in a bordure of little squares;
  3  five beasts passant, two, one and two;
  4  a little castle, a lion rampant, a cross flory and a chequered piece.
"""
import math, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'cultura')
FW, FH = 71.0, 91.0                    # the field, cm
S = 1024 / FW                          # px a cm, drawn at twice the size kept
W, H = 1024, int(round(FH * S))
rng = np.random.default_rng(321)


def px(p):
    return (p[0] * S, p[1] * S)


def new():
    im = Image.new('L', (W, H), 0)
    return im, ImageDraw.Draw(im)


def arr(im, blur=0.0):
    if blur > 0:
        im = im.filter(ImageFilter.GaussianBlur(blur * S))
    return np.asarray(im, np.float32) / 255.0


def pillow(im, r):
    """a flat shape made round: 0 at its edge, 1 inside it deeper than about r cm"""
    b = arr(im, r * 0.6)
    return np.sqrt(np.clip(2.0 * b - 1.0, 0.0, 1.0))


def smooth(pts, n=8):
    """Catmull-Rom through the points"""
    out = []
    p = [pts[0]] + list(pts) + [pts[-1]]
    for i in range(1, len(p) - 2):
        for k in range(n):
            t = k / n
            out.append(tuple(0.5 * ((2 * p[i][j]) + (-p[i - 1][j] + p[i + 1][j]) * t + (2 * p[i - 1][j] - 5 * p[i][j] + 4 * p[i + 1][j] - p[i + 2][j]) * t * t
                                    + (-p[i - 1][j] + 3 * p[i][j] - 3 * p[i + 1][j] + p[i + 2][j]) * t ** 3) for j in range(2)))
    out.append(pts[-1])
    return out


def tube(d, pts, w0, w1, curve=True):
    """a stroke tapering from w0 to w1 cm wide along the points"""
    path = smooth(pts) if curve else pts
    n = len(path)
    for i, q in enumerate(path):
        w = (w0 + (w1 - w0) * i / max(1, n - 1)) / 2.0
        d.ellipse([px((q[0] - w, q[1] - w)), px((q[0] + w, q[1] + w))], fill=255)
        if i:
            d.line([px(path[i - 1]), px(q)], fill=255, width=int(2 * w * S))


def volute(cx, cy, r, turns, a0, sense):
    """the points of a spiral curling in from radius r"""
    pts = []
    n = int(16 * turns) + 1
    for k in range(n + 1):
        t = k / n
        a = a0 + sense * t * turns * 2 * math.pi
        rr = r * (1.0 - 0.78 * t)
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    return pts


def leaf(d, base, tip, wd, lobes=3, bend=0.0):
    """an acanthus leaf from base to tip: lobed on both sides, bent a little"""
    bx, by = base
    tx, ty = tip
    L = math.hypot(tx - bx, ty - by)
    ux, uy = (tx - bx) / L, (ty - by) / L
    nx, ny = -uy, ux
    side1, side2 = [], []
    for k in range(41):
        t = k / 40
        r = math.sin(t * math.pi) ** 0.7 * wd * (0.75 + 0.25 * abs(math.sin(t * lobes * math.pi)))
        off = bend * math.sin(t * math.pi) * L * 0.25
        cx, cy = bx + ux * t * L + nx * off, by + uy * t * L + ny * off
        side1.append((cx + nx * r, cy + ny * r))
        side2.append((cx - nx * r, cy - ny * r))
    d.polygon([px(q) for q in side1 + side2[::-1]], fill=255)


def ell(d, cx, cy, rx, ry):
    d.ellipse([px((cx - rx, cy - ry)), px((cx + rx, cy + ry))], fill=255)


def dome(cx, cy, rx, ry):
    yy, xx = np.mgrid[0:H, 0:W]
    q = ((xx / S - cx) / rx) ** 2 + ((yy / S - cy) / ry) ** 2
    return np.sqrt(np.clip(1.0 - q, 0.0, 1.0))


# ---------------- the shield ----------------
SX0, SX1, SY0, SY1 = 18.2, 55.0, 31.5, 77.5            # its sides, its top, the tip of its round foot (cm)
MX, MY = 36.6, 53.8                                      # where the quarters meet
FOOT = 63.0                                              # where its sides turn into the round foot


def shield_poly(i=0.0):
    pts = [(SX0 + i, SY0 + i), (SX1 - i, SY0 + i)]
    cx, rx, ry = (SX0 + SX1) / 2, (SX1 - SX0) / 2 - i, SY1 - i - FOOT
    for k in range(33):
        a = k / 32 * math.pi
        pts.append((cx + math.cos(a) * rx, FOOT + math.sin(a) * ry))
    return [px(q) for q in pts]


def quarter(q):
    b = 2.6
    return {1: (SX0 + b, SY0 + b, MX - 0.6, MY - 0.6), 2: (MX + 0.6, SY0 + b, SX1 - b, MY - 0.6),
            3: (SX0 + b, MY + 0.6, MX - 0.6, SY1 - b), 4: (MX + 0.6, MY + 0.6, SX1 - b, SY1 - b)}[q]


def beast(d, x, y, s, face=-1):
    """a beast passant, side on, facing `face` (-1: to the left), s cm long"""
    f = face
    ell(d, x, y, 0.36 * s, 0.17 * s)                                                  # body
    ell(d, x + f * 0.42 * s, y - 0.2 * s, 0.14 * s, 0.12 * s)                          # head
    ell(d, x + f * 0.55 * s, y - 0.17 * s, 0.08 * s, 0.05 * s)                         # muzzle
    tube(d, [(x + f * 0.36 * s, y - 0.32 * s), (x + f * 0.38 * s, y - 0.4 * s)], 0.07 * s, 0.03 * s, False)   # ear
    for lx, ph in ((-0.26, 0.05), (-0.14, -0.05), (0.18, -0.05), (0.3, 0.05)):        # legs, striding
        tube(d, [(x + f * lx * s, y + 0.05 * s), (x + f * (lx + ph) * s, y + 0.25 * s), (x + f * (lx + ph * 1.6) * s, y + 0.42 * s)], 0.11 * s, 0.07 * s)
    tube(d, [(x - f * 0.34 * s, y - 0.05 * s), (x - f * 0.5 * s, y - 0.2 * s), (x - f * 0.42 * s, y - 0.4 * s), (x - f * 0.32 * s, y - 0.42 * s)], 0.06 * s, 0.03 * s)


def lion_rampant(d, x, y, s, face=-1):
    """upright on its hind legs, facing `face`, s cm tall"""
    f = face
    tube(d, [(x, y + 0.2 * s), (x + f * 0.03 * s, y), (x + f * 0.08 * s, y - 0.2 * s)], 0.26 * s, 0.2 * s)   # body
    ell(d, x + f * 0.13 * s, y - 0.32 * s, 0.12 * s, 0.11 * s)                          # head and mane
    ell(d, x + f * 0.24 * s, y - 0.3 * s, 0.06 * s, 0.045 * s)
    tube(d, [(x + f * 0.1 * s, y - 0.14 * s), (x + f * 0.26 * s, y - 0.2 * s), (x + f * 0.34 * s, y - 0.33 * s)], 0.07 * s, 0.05 * s)  # forepaws up
    tube(d, [(x + f * 0.08 * s, y - 0.05 * s), (x + f * 0.27 * s, y - 0.04 * s), (x + f * 0.34 * s, y - 0.12 * s)], 0.07 * s, 0.05 * s)
    tube(d, [(x + f * 0.02 * s, y + 0.25 * s), (x + f * 0.14 * s, y + 0.36 * s), (x + f * 0.2 * s, y + 0.48 * s)], 0.1 * s, 0.06 * s)   # hind legs
    tube(d, [(x - f * 0.04 * s, y + 0.27 * s), (x - f * 0.06 * s, y + 0.4 * s), (x + f * 0.0 * s, y + 0.5 * s)], 0.1 * s, 0.06 * s)
    tube(d, [(x - f * 0.08 * s, y + 0.25 * s), (x - f * 0.25 * s, y + 0.1 * s), (x - f * 0.2 * s, y - 0.1 * s), (x - f * 0.28 * s, y - 0.25 * s)], 0.05 * s, 0.03 * s)  # tail


def tower(d, x0, y0, x1, y1, merlons=3):
    d.rectangle([px((x0, y0 + (y1 - y0) * 0.2)), px((x1, y1))], fill=255)
    w = (x1 - x0) / (2 * merlons - 1)
    for k in range(merlons):
        d.rectangle([px((x0 + 2 * k * w, y0)), px((x0 + (2 * k + 1) * w, y0 + (y1 - y0) * 0.22))], fill=255)


def charges():
    """the carving in the quarters (0..1 over the shield's face)"""
    out = np.zeros((H, W), np.float32)
    # 1: two big roundels, then roundels in four columns either side of a staff
    x0, y0, x1, y1 = quarter(1)
    cx = (x0 + x1) / 2
    for bx in (x0 + 3.6, x1 - 3.6):
        out = np.maximum(out, dome(bx, y0 + 2.9, 2.4, 2.2) * 0.95)
    for col in (-6.2, -3.4, 3.4, 6.2):
        for row in range(5):
            out = np.maximum(out, dome(cx + col, y0 + 7.6 + row * 2.75, 1.15, 1.05) * 0.85)
    im, d = new()
    d.rounded_rectangle([px((cx - 0.7, y0 + 1.0)), px((cx + 0.7, y1 - 0.8))], radius=int(0.7 * S), fill=255)
    ell(d, cx, y0 + 1.6, 1.3, 1.1)
    out = np.maximum(out, pillow(im, 0.8) * 0.8)
    # 2: a bordure of little squares; a tower and an eagle with its wings spread on it
    x0, y0, x1, y1 = quarter(2)
    im, d = new()
    k = 0
    x = x0
    while x < x1 - 1.0:
        if k % 2 == 0:
            for yy in (y0, y1 - 1.3):
                d.rectangle([px((x, yy)), px((x + 1.3, yy + 1.3))], fill=255)
        x += 1.6
        k += 1
    k = 0
    y = y0
    while y < y1 - 1.0:
        if k % 2 == 0:
            for xx in (x0, x1 - 1.3):
                d.rectangle([px((xx, y)), px((xx + 1.3, y + 1.3))], fill=255)
        y += 1.6
        k += 1
    out = np.maximum(out, arr(im, 0.25) * 0.7)
    mx = (x0 + x1) / 2
    im, d = new()
    tower(d, mx - 4.3, y0 + 9.5, mx + 4.3, y1 - 2.4)
    out = np.maximum(out, pillow(im, 0.9) * 0.85)
    im, d = new()
    d.rectangle([px((mx - 1.2, y1 - 6.2)), px((mx + 1.2, y1 - 2.4))], fill=255)
    ell(d, mx, y1 - 6.2, 1.2, 1.2)
    for wx in (-2.6, 2.6):
        d.rectangle([px((mx + wx - 0.5, y0 + 13.0)), px((mx + wx + 0.5, y0 + 14.6))], fill=255)
    out -= arr(im, 0.3) * 0.4
    im, d = new()                                                          # the eagle
    ell(d, mx, y0 + 6.6, 1.5, 2.5)
    ell(d, mx - 0.4, y0 + 3.6, 0.9, 0.85)
    tube(d, [(mx - 1.0, y0 + 3.5), (mx - 2.0, y0 + 3.8)], 0.5, 0.2, False)
    for s in (-1, 1):
        for j, (a, b) in enumerate((((1.0, 5.5), (6.2, 2.6)), ((1.0, 6.5), (6.8, 4.8)), ((1.0, 7.5), (6.2, 7.0)))):
            tube(d, [(mx + s * a[0], y0 + a[1]), (mx + s * (a[0] + b[0]) / 2, y0 + (a[1] + b[1]) / 2 - 0.6), (mx + s * b[0], y0 + b[1])], 1.4, 0.5)
    tube(d, [(mx, y0 + 8.5), (mx - 1.3, y0 + 9.5)], 0.9, 0.6, False)
    tube(d, [(mx, y0 + 8.5), (mx + 1.3, y0 + 9.5)], 0.9, 0.6, False)
    out = np.maximum(out, pillow(im, 0.6) * 0.9)
    # 3: five beasts passant, two, one and two
    x0, y0, x1, y1 = quarter(3)
    im, d = new()
    for bx, by in ((0.29, 0.17), (0.72, 0.17), (0.5, 0.44), (0.32, 0.7), (0.7, 0.7)):
        beast(d, x0 + (x1 - x0) * bx, y0 + (y1 - y0) * by, 6.4)
    out = np.maximum(out, pillow(im, 0.6) * 0.85)
    # 4: a little castle, a lion rampant, a cross flory, a chequered piece
    x0, y0, x1, y1 = quarter(4)
    im, d = new()
    tower(d, x0 + 1.2, y0 + 1.4, x0 + 5.6, y0 + 6.6)
    lion_rampant(d, x0 + 10.6, y0 + 9.0, 11.0)
    ccx, ccy, cs = x0 + 3.6, y0 + 11.6, 4.0
    d.rectangle([px((ccx - 0.6, ccy - cs / 2)), px((ccx + 0.6, ccy + cs / 2))], fill=255)
    d.rectangle([px((ccx - cs / 2, ccy - 0.6)), px((ccx + cs / 2, ccy + 0.6))], fill=255)
    for ddx, ddy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
        ell(d, ccx + ddx * cs / 2, ccy + ddy * cs / 2, 0.85, 0.85)
    out = np.maximum(out, pillow(im, 0.6) * 0.85)
    im, d = new()
    for i in range(4):
        for j in range(3):
            if (i + j) % 2 == 0:
                d.rectangle([px((x0 + 2.4 + i * 1.3, y1 - 6.4 + j * 1.3)), px((x0 + 3.6 + i * 1.3, y1 - 5.2 + j * 1.3))], fill=255)
    d.rectangle([px((x0 + 2.0, y1 - 6.8)), px((x0 + 7.9, y1 - 2.4))], outline=255, width=int(0.45 * S))
    out = np.maximum(out, arr(im, 0.25) * 0.7)
    return out


# ---------------- the cartouche round it ----------------
def mantling():
    """the acanthus scrolls, leaves and the draped mantle: drawn as several layers, each rounded on its own"""
    layers = []
    # the scrolls: C and S curves with their volutes, mirrored on each side but not quite alike (as carved)
    im, d = new()
    for s in (-1, 1):
        def X(x):
            return FW / 2 + s * (x - FW / 2)
        # up the side, from the foot to the top corner, ending in a curl outward
        tube(d, [(X(14.5), 82.0), (X(9.0), 74.0), (X(7.5), 64.0), (X(9.5), 55.0), (X(7.0), 46.0), (X(6.5), 36.0), (X(9.5), 27.0), (X(13.5), 21.5)], 3.6, 2.4)
        tube(d, volute(X(8.6), 21.0, 4.9, 1.15, math.pi * (0.1 if s < 0 else 0.9), -s), 1.9, 0.6)
        # a C-scroll hugging the shield's side, curling at both ends
        tube(d, [(X(15.2), 42.0), (X(12.5), 48.0), (X(12.5), 55.0), (X(15.0), 61.0)], 2.6, 2.6)
        tube(d, volute(X(13.2), 40.0, 3.2, 1.0, math.pi * (1.5), s), 1.8, 0.6)
        tube(d, volute(X(13.8), 63.5, 3.4, 1.0, math.pi * 0.5, -s), 1.8, 0.6)
        # the big S at the foot, from under the shield out to a curl at the corner
        tube(d, [(X(28.0), 79.0), (X(23.0), 82.5), (X(17.5), 82.0), (X(14.0), 78.0)], 3.4, 2.6)
        tube(d, volute(X(13.0), 74.5, 4.5, 1.2, math.pi * 0.5, s), 2.0, 0.6)
        tube(d, [(X(28.0), 79.0), (X(30.5), 84.5), (X(27.0), 88.0)], 2.4, 1.4)
        # a curl at the top corner, the mantle's end
        tube(d, volute(X(15.5), 9.5, 4.2, 1.1, math.pi * (0.0 if s < 0 else 1.0), s), 1.8, 0.6)
    layers.append((pillow(im, 1.4), 0.8))
    # the leaves: along the scrolls, pointing out and down
    im, d = new()
    for s in (-1, 1):
        def X(x):
            return FW / 2 + s * (x - FW / 2)
        for base, tip, wd, bend in (((X(8.0), 29.0), (X(1.5), 35.0), 2.9, 0.5), ((X(7.0), 39.0), (X(1.2), 46.5), 2.7, -0.4), ((X(8.0), 51.0), (X(1.5), 57.0), 2.6, 0.4),
                                    ((X(8.0), 61.0), (X(1.5), 68.5), 2.9, -0.5), ((X(9.5), 70.0), (X(2.5), 78.5), 2.7, 0.4), ((X(11.5), 26.0), (X(16.0), 33.5), 2.4, 0.5),
                                    ((X(11.0), 16.5), (X(3.5), 12.0), 2.8, -0.5), ((X(19.5), 15.5), (X(13.0), 5.0), 3.2, 0.6), ((X(21.0), 83.0), (X(16.5), 90.0), 2.5, -0.4),
                                    ((X(11.5), 80.0), (X(3.0), 88.0), 2.8, 0.5), ((X(14.5), 46.0), (X(17.6), 52.5), 1.5, 0.3), ((X(24.0), 18.0), (X(16.5), 22.5), 2.8, -0.4),
                                    ((X(25.0), 84.0), (X(29.0), 90.5), 2.0, 0.4), ((X(12.0), 58.0), (X(17.0), 61.5), 1.6, -0.3)):
            leaf(d, base, tip, wd, 3, bend)
    layers.append((pillow(im, 1.0), 0.62))
    # the rosette on the right, as on the stone
    im, d = new()
    for k in range(6):
        a = k / 6 * 2 * math.pi
        ell(d, 60.5 + math.cos(a) * 1.9, 37.5 + math.sin(a) * 1.9, 1.3, 1.3)
    layers.append((pillow(im, 0.7) * 0.85 + dome(60.5, 37.5, 1.1, 1.1) * 0.25, 0.7))
    # the mantle draped under the helmet, its folds hanging over the shield's top
    im, d = new()
    d.polygon([px(q) for q in smooth([(19.0, 30.5), (22.0, 24.5), (28.0, 22.0), (35.0, 23.5), (42.0, 22.0), (48.5, 24.0), (52.5, 30.5), (46.0, 29.0), (41.0, 31.0), (35.5, 29.0), (30.0, 31.0), (24.5, 29.0)])], fill=255)
    layers.append((pillow(im, 1.6), 0.75))
    out = np.zeros((H, W), np.float32)
    for h, top in layers:
        out = np.maximum(out, h * top)
    # the folds of the mantle: grooves down it
    im, d = new()
    for x in (24.0, 29.5, 35.0, 40.5, 46.0):
        d.line([px((x, 23.5)), px((x + 0.5, 30.5))], fill=255, width=int(0.5 * S))
    out -= arr(im, 0.4) * 0.12 * (out > 0.3)
    # the leaves' midribs: a groove along each
    return out


def helmet():
    """seen from the front a little turned: its dome, the visor's bars, the gorget, plumes curling to the right"""
    h = dome(34.8, 13.0, 7.6, 7.9) * 1.0
    im, d = new()
    for k in range(5):                                                    # the visor: bars down its lower half
        x = 30.6 + k * 2.1
        d.line([px((x, 12.8)), px((x + 0.2, 19.8))], fill=255, width=int(0.55 * S))
    d.line([px((28.2, 12.6)), px((41.4, 12.6))], fill=255, width=int(0.7 * S))
    h -= arr(im, 0.25) * 0.22 * (h > 0.15)
    im, d = new()                                                          # the gorget, flaring over the mantle
    d.chord([px((27.5, 15.5)), px((42.2, 25.5))], 0, 180, fill=255)
    h = np.maximum(h, pillow(im, 1.4) * 0.82)
    im, d = new()                                                          # the plumes, curling up and over to the right
    for a, b, c, w in (((31.0, 6.5), (31.5, 2.0), (35.5, 0.8), 2.6), ((34.5, 5.5), (37.0, 1.5), (41.0, 2.2), 2.4),
                       ((37.5, 6.0), (41.5, 3.6), (43.2, 7.5), 2.2), ((39.5, 8.0), (43.8, 8.2), (43.4, 12.5), 2.0), ((40.5, 11.0), (44.2, 13.5), (42.6, 17.0), 1.6)):
        tube(d, [a, b, c], w, w * 0.45)
    h = np.maximum(h, pillow(im, 1.0) * 0.85)
    return h


def shell():
    """the scallop under the shield's foot: its hinge up, the ribs fanning down"""
    im, d = new()
    cx, cy = 35.5, 78.5
    d.pieslice([px((cx - 10.0, cy - 9.0)), px((cx + 10.0, cy + 11.5))], 20, 160, fill=255)
    ell(d, cx, cy + 0.6, 2.5, 1.8)
    base = pillow(im, 1.2)
    im, d = new()
    for a in range(28, 160, 12):
        d.line([px((cx, cy)), px((cx + math.cos(math.radians(a)) * 10.0, cy + math.sin(math.radians(a)) * 10.2))], fill=255, width=int(0.5 * S))
    grooves = arr(im, 0.35)
    return np.clip(base * 0.8 - grooves * base * 0.25, 0, 1)


def main():
    hf = mantling()
    hf = np.maximum(hf, helmet())
    hf = np.maximum(hf, shell())
    im, d = new()
    d.polygon(shield_poly(), fill=255)
    sh = arr(im, 0.25)
    im, d = new()
    d.polygon(shield_poly(2.2), fill=255)
    inner = arr(im, 0.25)
    im, d = new()                                                          # the line between the quarters, and the bordure's saltires
    d.line([px((MX, SY0 + 2.2)), px((MX, SY1 - 2.2))], fill=255, width=int(0.6 * S))
    d.line([px((SX0 + 2.2, MY)), px((SX1 - 2.2, MY))], fill=255, width=int(0.6 * S))
    marks = [(SX0 + 1.1, SY0 + 4.0 + k * 4.4) for k in range(8)] + [(SX1 - 1.1, SY0 + 4.0 + k * 4.4) for k in range(8)] + [(SX0 + 4.0 + k * 4.1, SY0 + 1.1) for k in range(9)]
    for k in range(1, 8):
        a = k / 8 * math.pi
        marks.append(((SX0 + SX1) / 2 + math.cos(a) * ((SX1 - SX0) / 2 - 1.1), FOOT + math.sin(a) * (SY1 - FOOT - 1.1)))
    for x, y in marks:
        d.line([px((x - 0.65, y - 0.65)), px((x + 0.65, y + 0.65))], fill=255, width=int(0.32 * S))
        d.line([px((x - 0.65, y + 0.65)), px((x + 0.65, y - 0.65))], fill=255, width=int(0.32 * S))
    cuts = arr(im, 0.15)
    face = 0.6 + (sh - inner) * 0.1                                        # the bordure stands a little prouder
    hf = np.where(sh > 0.02, np.maximum(hf * (1.0 - sh), face * sh), hf)
    hf = hf + charges() * inner * 0.32 - cuts * sh * 0.12
    # the stone's grain and wear
    n1 = np.asarray(Image.fromarray((rng.random((H // 16, W // 16)) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(6)), np.float32) / 255.0
    n2 = rng.random((H, W)).astype(np.float32)
    hf = hf + (n1 - 0.5) * 0.05 + (n2 - 0.5) * 0.015

    k = 7.0                                                                # how steep the carving reads
    gy, gx = np.gradient(hf * k)
    nx, ny, nz = -gx, gy, np.ones_like(hf)                                 # (y up in a normal map; the picture's y runs down)
    ln = np.sqrt(nx * nx + ny * ny + nz * nz)
    nx, ny, nz = nx / ln, ny / ln, nz / ln
    L = np.array([-0.4, 0.55, 0.73])
    L /= np.linalg.norm(L)
    lit = np.clip(nx * L[0] + ny * L[1] + nz * L[2], 0, 1) / L[2]
    wide = np.asarray(Image.fromarray((np.clip(hf, 0, 1.4) / 1.4 * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.6 * S)), np.float32) / 255.0 * 1.4
    cavity = np.clip(1.0 + (hf - wide) * 1.6, 0.5, 1.12)                   # hollows darker, edges catching the light
    shade = (0.38 + 0.62 * lit) * cavity
    base = np.array([232, 214, 184], np.float32) / 255.0                # (cream, as the frame's stone in the game)
    st = np.asarray(Image.fromarray((rng.random((4, 9)) * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(30)), np.float32) / 255.0
    grime = 1.0 - np.clip(st - 0.5, 0, 1) * 0.35 - np.clip(0.25 - hf, 0, 0.25) * 0.3
    warm = np.stack([1.0 + (n1 - 0.5) * 0.08, 1.0 + (n1 - 0.5) * 0.02, 1.0 - (n1 - 0.5) * 0.08], -1)
    rgb = np.clip(base[None, None, :] * warm * (shade * grime)[:, :, None], 0, 1)
    os.makedirs(OUT, exist_ok=True)
    alb = Image.fromarray((rgb * 255).astype(np.uint8)).resize((W // 2, H // 2), Image.LANCZOS)
    alb.save(os.path.join(OUT, 'escudo.png'))
    nm = np.stack([nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5], -1)
    Image.fromarray((nm * 255).astype(np.uint8)).resize((W // 2, H // 2), Image.LANCZOS).save(os.path.join(OUT, 'escudo_n.png'))
    print(os.path.join(OUT, 'escudo.png'), alb.size)


if __name__ == '__main__':
    main()
