"""The town far off from the cemetery's zone, as a band round the horizon (lejanias.gd in the game).

Luis, 25/11/2026: «mirando hacia el sur se podría ver un .PNG del pueblo, parecido a lo que hicimos con el castillo de
la muela». The game draws the pictures itself (python tools/run_tests.py lejanias: lejanias_foto.gd), twelve of 30
degrees round from the zone's middle, by day and at night, into its user folder (the log says where); this turns them
into the band: 32 px a degree, from 3 degrees under the horizon to 5 over it, in four quarters from north on
(godot/assets/autovia/pueblo_dia_0..3.png and pueblo_noche_0..3.png).

    python tools/cementerio/lejanias.py "C:/Users/.../app_userdata/<project>/lejanias"

The pictures come from the viewport with its clear see-through: their colour is already times their alpha (what is
averaged at an edge is the colour with the clear's black), so they are sampled as they are and divided by the alpha
at the end; and the colour of the nearest thing is carried up into the clear over it (so that far off, where the
game averages the picture down, the edges do not go dark).
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..', '..')
PX = 32                      # a degree
LO, HI = -3.0, 5.0           # the band: under and over the horizon (lejanias.gd BAND)


def main():
    src = sys.argv[1]
    meta = json.load(open(os.path.join(ROOT, 'godot', 'data', 'lejanias.json'), encoding='utf-8'))
    tw, th = meta['tile']
    step = float(meta['fov'])
    n = int(round(360.0 / step))
    f = (tw / 2.0) / math.tan(math.radians(step / 2.0))
    out_dir = os.path.join(ROOT, 'godot', 'assets', 'autovia')
    os.makedirs(out_dir, exist_ok=True)
    rows = int((HI - LO) * PX)
    for moment in ('dia', 'noche'):
        tiles = []
        for t in range(n):
            im = np.asarray(Image.open(os.path.join(src, '%s_%02d.png' % (moment, t))).convert('RGBA'), dtype=np.float32) / 255.0
            tiles.append(im)
        for q in range(4):
            cols = 90 * PX
            a = q * 90.0 + (np.arange(cols) + 0.5) / PX                 # bearings
            e = HI - (np.arange(rows) + 0.5) / PX                       # over the horizon
            A, E = np.meshgrid(np.radians(a), np.radians(e))
            t = np.round(np.degrees(A) / step).astype(int) % n
            da = A - np.radians(t * step)
            da = (da + math.pi) % (2 * math.pi) - math.pi
            xc = np.cos(E) * np.sin(da)
            yc = np.sin(E)
            zc = np.cos(E) * np.cos(da)
            u = tw / 2.0 + f * xc / zc - 0.5
            v = th / 2.0 - f * yc / zc - 0.5
            out = np.zeros((rows, cols, 4), dtype=np.float32)
            for k in range(n):
                m = t == k
                if not m.any():
                    continue
                uu = np.clip(u[m], 0, tw - 1.001)
                vv = np.clip(v[m], 0, th - 1.001)
                u0 = np.floor(uu).astype(int)
                v0 = np.floor(vv).astype(int)
                fu = (uu - u0)[:, None]
                fv = (vv - v0)[:, None]
                im = tiles[k]
                c = (im[v0, u0] * (1 - fu) * (1 - fv) + im[v0, u0 + 1] * fu * (1 - fv)
                     + im[v0 + 1, u0] * (1 - fu) * fv + im[v0 + 1, u0 + 1] * fu * fv)
                out[m] = c
            alpha = out[:, :, 3:4]
            rgb = np.where(alpha > 0.004, out[:, :, :3] / np.maximum(alpha, 0.004), 0.0)
            rgb = np.clip(rgb, 0.0, 1.0)
            # the colour of what is under it carried up into the clear (column by column, from the bottom up)
            last = rgb[rows - 1].copy()
            for r in range(rows - 1, -1, -1):
                solid = alpha[r, :, 0] > 0.5
                last[solid] = rgb[r, solid]
                rgb[r, ~solid] = np.where(alpha[r, ~solid] > 0.004, rgb[r, ~solid], last[~solid])
            img = np.concatenate([rgb, alpha], axis=2)
            Image.fromarray((img * 255.0 + 0.5).astype(np.uint8), 'RGBA').save(os.path.join(out_dir, 'pueblo_%s_%d.png' % (moment, q)), optimize=True)
            print(moment, q, 'cover %.0f %%' % (100.0 * float((alpha > 0.5).mean())))


if __name__ == '__main__':
    main()
