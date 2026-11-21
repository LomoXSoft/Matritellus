"""The flags of the park of the Paseo del Cristo: irregular slate, blue-grey and grey with the odd buff or rusty one,
in grey cement joints (the Street View pictures of 2013 and 2024, tools/paseo/capturas.py), bigger than the
Toledano's. Drawn here (nobody's photograph): a field of random points, each flag the cell of its point; it repeats
without a seam. Writes godot/assets/paseo/losas.png (one tile is 3.6 m across in the game: flags of about 45 cm).

    python tools/paseo/losas.py [size_px]
"""
import os, sys
import numpy as np
from PIL import Image, ImageFilter

N = int(sys.argv[1]) if len(sys.argv) > 1 else 512
rng = np.random.default_rng(2013)
G = 8                                           # a jittered grid of points: flags of about 45 cm
pts = np.array([[(i + rng.uniform(0.1, 0.9)) / G, (j + rng.uniform(0.1, 0.9)) / G] for i in range(G) for j in range(G)])
tones = np.array([(0x8a, 0x90, 0x96), (0x7a, 0x80, 0x88), (0x96, 0x98, 0x98), (0x6e, 0x74, 0x7c), (0xa2, 0x9e, 0x94),
                  (0x84, 0x86, 0x84), (0x9a, 0x8a, 0x76), (0x8e, 0x94, 0x9c)], float)
pick = rng.choice(len(tones), len(pts), p=[0.22, 0.18, 0.15, 0.12, 0.08, 0.13, 0.04, 0.08])
shade = rng.uniform(0.9, 1.1, len(pts))
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
img += rng.normal(0, 3.5, (N, N, 1))                                    # the grain of the stone
joint = (d2 - d1) < 0.013                                                # the cement between flags
img[joint] = (0x9c, 0x9a, 0x92)
im = Image.fromarray(np.clip(img, 0, 255).astype('uint8'), 'RGB').filter(ImageFilter.GaussianBlur(0.6))
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'godot', 'assets', 'paseo', 'losas.png')
os.makedirs(os.path.dirname(out), exist_ok=True)
im.save(out)
print(out, im.size)
