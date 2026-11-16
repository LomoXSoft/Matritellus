"""The paving of the Plazuela del Toledano: irregular flags of slate -- grey, blue-grey, buff, a few rusty -- in pale
mortar, as in the street photos. Drawn here (nobody's photograph): a field of random points, each flag the cell of
its point; it repeats without a seam. Writes godot/assets/toledano/losas.png (one tile is 3 m across in the game: flags of about a third of a metre).

    python tools/toledano/losas.py [size_px]
"""
import os, sys
import numpy as np
from PIL import Image, ImageFilter

N = int(sys.argv[1]) if len(sys.argv) > 1 else 512
rng = np.random.default_rng(1947)
G = 9                                           # a jittered grid of points: flags of about 45 cm
pts = np.array([[(i + rng.uniform(0.12, 0.88)) / G, (j + rng.uniform(0.12, 0.88)) / G] for i in range(G) for j in range(G)])
tones = np.array([(0x92, 0x92, 0x90), (0x84, 0x87, 0x8a), (0xa6, 0x9f, 0x91), (0x9a, 0x93, 0x87), (0x7a, 0x7d, 0x80), (0xb0, 0xa7, 0x94), (0x98, 0x82, 0x6e), (0x8b, 0x8c, 0x88)], float)
pick = rng.choice(len(tones), len(pts), p=[0.2, 0.17, 0.16, 0.14, 0.11, 0.1, 0.05, 0.07])
shade = rng.uniform(0.9, 1.08, len(pts))
ys, xs = np.mgrid[0:N, 0:N]
u = (xs + 0.5) / N
v = (ys + 0.5) / N
d1 = np.full((N, N), 9.0); d2 = np.full((N, N), 9.0); who = np.zeros((N, N), int)
for k, (px, py) in enumerate(pts):
    for ox in (-1, 0, 1):
        for oy in (-1, 0, 1):
            d = np.hypot(u - px - ox, v - py - oy)
            nearer = d < d1
            d2 = np.where(nearer, d1, np.minimum(d2, d))
            who = np.where(nearer, k, who)
            d1 = np.where(nearer, d, d1)
img = tones[pick[who]] * shade[who][..., None]
img += rng.normal(0, 3.0, (N, N, 1))                                    # the grain of the stone
joint = (d2 - d1) < 0.011                                                # the mortar between flags
img[joint] = (0xc9, 0xc0, 0xa8)
im = Image.fromarray(np.clip(img, 0, 255).astype('uint8'), 'RGB').filter(ImageFilter.GaussianBlur(0.6))
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'godot', 'assets', 'toledano', 'losas.png')
im.save(out)
print(out, im.size)
