"""The floors of the Travesía del Clavel (godot/assets/travesia/), drawn here.

    python tools/travesia/dibujos.py

baldosa.png  the walk's paving, a 1.6 m tile: squares of 40 cm, cream and dull red in chequers, each of four little
             pavers with their grid of studs (Street View, November 2024, and the user's pictures)
rayado.png   the grooved concrete of the garage's lane, a 0.8 m tile: grooves across it
laja.png     the crazy paving of flat stones, dark red and cream, that clads the foot of the corner houses: a 1.6 m tile
After adding or changing them: Godot --headless --path godot --import.
"""
import os, random
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'godot', 'assets', 'travesia')
os.makedirs(OUT, exist_ok=True)


def grain(im, rnd, k):
    px = im.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            n = rnd.randint(-k, k)
            px[x, y] = tuple(max(0, min(255, c + n)) for c in px[x, y])
    return im


def baldosa():
    n, sq = 512, 128
    rnd = random.Random(7)
    im = Image.new('RGB', (n, n))
    d = ImageDraw.Draw(im)
    cream, red = (216, 198, 164), (178, 114, 100)
    for j in range(4):
        for i in range(4):
            base = cream if (i + j) % 2 == 0 else red
            for b in range(2):
                for a in range(2):
                    t = rnd.randint(-7, 7)
                    c = tuple(max(0, min(255, v + t)) for v in base)
                    x0, y0 = i * sq + a * 64, j * sq + b * 64
                    d.rectangle([x0, y0, x0 + 63, y0 + 63], fill=tuple(int(v * 0.8) for v in c))
                    for q in range(4):
                        for p in range(4):
                            d.rectangle([x0 + 2 + p * 15.5, y0 + 2 + q * 15.5, x0 + 14 + p * 15.5, y0 + 14 + q * 15.5], fill=c)
    im = grain(im, rnd, 5).filter(ImageFilter.SMOOTH)
    im.save(os.path.join(OUT, 'baldosa.png'))
    print('baldosa.png', im.size)


def rayado():
    n = 256
    rnd = random.Random(11)
    im = Image.new('RGB', (n, n), (196, 188, 172))
    d = ImageDraw.Draw(im)
    for y in range(0, n, 16):
        d.rectangle([0, y, n, y + 3], fill=(150, 144, 132))
        d.line([(0, y + 4), (n, y + 4)], fill=(212, 204, 188))
    im = grain(im, rnd, 6).filter(ImageFilter.SMOOTH)
    im.save(os.path.join(OUT, 'rayado.png'))
    print('rayado.png', im.size)


def laja():
    n = 512
    rnd = random.Random(23)
    im = Image.new('RGB', (n, n), (150, 124, 108))
    d = ImageDraw.Draw(im)
    pts = [(rnd.uniform(0, n), rnd.uniform(0, n)) for _ in range(46)]
    cols = [(150, 78, 70), (168, 92, 80), (132, 66, 62), (206, 178, 150), (188, 150, 128), (160, 84, 74)]
    px = im.load()
    for y in range(n):                           # (a Voronoi of flat stones, wrapping round so the tile repeats)
        for x in range(n):
            best, second, bi = 1e9, 1e9, 0
            for i, (a, b) in enumerate(pts):
                dx = min(abs(x - a), n - abs(x - a)); dy = min(abs(y - b), n - abs(y - b))
                dd = dx * dx + dy * dy
                if dd < best:
                    second, best, bi = best, dd, i
                elif dd < second:
                    second = dd
            if second ** 0.5 - best ** 0.5 > 5.0:
                c = cols[bi % len(cols)]
                t = (bi * 37) % 17 - 8
                px[x, y] = tuple(max(0, min(255, v + t)) for v in c)
            else:
                px[x, y] = (214, 200, 180)       # (the mortar between them)
    im = grain(im, rnd, 6).filter(ImageFilter.SMOOTH)
    im.save(os.path.join(OUT, 'laja.png'))
    print('laja.png', im.size)


if __name__ == '__main__':
    baldosa()
    rayado()
    laja()
