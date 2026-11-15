"""The pavings drawn here (no photos): the grey granite setts laid in rows across the pedestrian Calle Real and the
reddish brick pavers of the bands along its houses; and the grey concrete pavers of streets paved but open to cars.
Each image is a 2 m square tile.
    python tools/empedrado_tex.py  ->  godot/assets/empedrado/adoquin.png, ladrillo.png, adoquin_gris.png
"""
import os, random
from PIL import Image, ImageDraw, ImageFilter
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'godot', 'assets', 'empedrado')
os.makedirs(OUT, exist_ok=True)
N = 512                                   # px for 2 m: 1 px = 3.9 mm
rnd = random.Random(15)

def stones(w_px, h_px, base, spread, joint, jw, offset_rows=True, name='x', grey=False):
    im = Image.new('RGB', (N, N), joint)
    d = ImageDraw.Draw(im)
    rows = N // h_px
    for r in range(rows):
        y0 = r * h_px
        off = (w_px // 2) * (r % 2) if offset_rows else 0
        x = -off
        while x < N:
            w = w_px + rnd.randint(-2, 2)
            t = rnd.uniform(-spread, spread)
            c = tuple(max(0, min(255, int(base[i] + t + rnd.uniform(-6, 6)))) for i in range(3))
            for xx in (x, x + N):                 # (wraps round so the tile repeats without a seam)
                d.rounded_rectangle([xx + jw, y0 + jw, xx + w - jw, y0 + h_px - jw], radius=max(2, jw), fill=c)
            for xx in (x - N,):
                d.rounded_rectangle([xx + jw, y0 + jw, xx + w - jw, y0 + h_px - jw], radius=max(2, jw), fill=c)
            x += w
    px = im.load()
    for y in range(N):                            # a little grain on every stone
        for x in range(N):
            r, g, b = px[x, y]
            n = rnd.randint(-7, 7)
            px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)))
    im = im.filter(ImageFilter.SMOOTH)
    if grey:                                      # (concrete has no colour of its own: the grain stays, the tints go)
        im = im.convert('L').convert('RGB')
    im.save(os.path.join(OUT, name))
    print(name, im.size)

stones(26, 26, (150, 148, 144), 22, (78, 76, 72), 2, True, 'adoquin.png')       # setts about 10 cm
stones(51, 26, (138, 96, 80), 14, (160, 148, 132), 2, True, 'ladrillo.png')     # pavers about 20 x 10 cm
stones(51, 26, (132, 132, 128), 9, (96, 96, 92), 2, True, 'adoquin_gris.png', grey=True)  # the grey concrete pavers, 20 x 10 cm, of the west end of the Calle de Santo Domingo (open to cars)
