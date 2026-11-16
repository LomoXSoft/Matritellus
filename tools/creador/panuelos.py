"""Draws the cloth of each peña's neckerchief (the user, 16 November 2026: "Un pañuelo del color de la peña con el
graffiti estampado detrás"): godot/assets/creador/panuelo_<id>.png, one per peña.

    python tools/creador/panuelos.py

The picture is the triangle of cloth that hangs down your back, as chara.gd lays it on the body: its top edge along the
top of the picture, its point at the middle of the bottom. Inside it: the peña's colour, a little weave, a hem with its
stitching round the two lower edges, and the peña's logo (godot/assets/penas/<id>.png) printed on it, a little faded
into the cloth, as a print on cotton is. Outside the triangle the colour simply goes on (it is never seen).
Our own drawing: nothing of the photo it was asked from (its crest and its words) is in it.
"""
import os
import random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PENAS = os.path.join(ROOT, 'godot', 'assets', 'penas')
OUT = os.path.join(ROOT, 'godot', 'assets', 'creador')
IDS = ['nietos', 'croquetilla', 'bordillo', 'centradito', 'costrola', 'al_prao']
COLOURS = ['2f63d6', 'f28a00', 'f2c200', '8cc63f', 'd42a1e', '1e8c3a']      # creator.gd KERCHIEFS
S = 512


def hexcol(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


def weave(size, seed):
    """a faint cotton weave: fine threads across and down, a little uneven"""
    rnd = random.Random(seed)
    img = Image.new('L', (size, size), 128)
    d = ImageDraw.Draw(img)
    for y in range(0, size, 3):
        d.line([(0, y), (size, y)], fill=128 + rnd.randint(-10, 10))
    for x in range(0, size, 3):
        d.line([(x, 0), (x, size)], fill=128 + rnd.randint(-8, 8))
    return img.filter(ImageFilter.GaussianBlur(0.6))


def cloth(pid, hexc, seed):
    base = hexcol(hexc)
    img = Image.new('RGB', (S, S), base)
    # the weave, as light and shade over the colour
    w = weave(S, seed)
    lit = Image.new('RGB', (S, S), shade(base, 1.08))
    dark = Image.new('RGB', (S, S), shade(base, 0.9))
    img = Image.composite(lit, dark, w)
    d = ImageDraw.Draw(img)
    # the hem down the two lower edges (the top is folded round the neck): a darker band, and its stitching
    tip = (S / 2, S - 2)
    left, right = (2, 2), (S - 2, 2)
    hem = shade(base, 0.78)
    d.line([left, tip], fill=hem, width=22)
    d.line([right, tip], fill=hem, width=22)
    stitch = shade(base, 1.25) if sum(base) < 380 else shade(base, 0.62)
    for a, b in [(left, tip), (right, tip)]:
        n = 46
        for i in range(n):
            if i % 2:
                continue
            t0, t1 = i / n, (i + 0.7) / n
            p0 = (a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0)
            p1 = (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)
            inward = 16 if a == left else -16          # (inside the hem)
            d.line([(p0[0] + inward, p0[1]), (p1[0] + inward, p1[1])], fill=stitch, width=3)
    # the logo, printed in the widest part of the point: a little faded into the cloth and taking its weave
    logo = Image.open(os.path.join(PENAS, pid + '.png')).convert('RGBA')
    box = 250
    k = box / max(logo.width, logo.height)
    logo = logo.resize((int(logo.width * k), int(logo.height * k)), Image.LANCZOS)
    cx, cy = S // 2, 170
    at = (cx - logo.width // 2, cy - logo.height // 2)
    rgb = logo.convert('RGB')
    wl = w.crop((at[0], at[1], at[0] + logo.width, at[1] + logo.height)).point(lambda v: 255 - (128 - v) * 2 if v < 128 else 255)
    rgb = ImageChops.multiply(rgb, Image.merge('RGB', [wl] * 3))
    alpha = logo.getchannel('A').point(lambda v: int(v * 0.9))
    img.paste(rgb, at, alpha)
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, 'panuelo_%s.png' % pid))


if __name__ == '__main__':
    for i, (pid, hc) in enumerate(zip(IDS, COLOURS)):
        cloth(pid, hc, 7 + i)
    print('written', len(IDS), 'neckerchiefs in', OUT)
