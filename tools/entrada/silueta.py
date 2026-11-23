"""The outline of Don Quixote on Rocinante, the cut steel sheet on the welcome wall at the north entrance (the old
Madrid-Cádiz road), traced from a Street View picture that sees the wall almost square on (November 2024):

    python tools/molino/panos.py foto cTw9zzGaau7e70OfFji3sA OUT.jpg 205.9 -1 12
    python -I tools/entrada/silueta.py OUT.jpg   ->  godot/data/quijote.json

(The picture is Google's: it stays out of the repository, in a scratch folder.) In that picture the wall's face runs
from x 240 to x 805 and its foot is at y 512; it is 43 m away and seen 14.6 degrees off square, so a pixel is
0.00903 m across and 0.00874 m up (the wall comes out 5.10 m long and 3.18 m high, as the other cameras say).
The outline is written in the wall's own frame: x along the wall from its left end (as seen from the road), y up
from its foot. The lance is not traced (above the wall it stands against the trees): entrada.gd draws it as a bar
from LANCE[0] to LANCE[1].
"""
import json, os, sys
import cv2, numpy as np
from shapely.geometry import Polygon, LineString
from shapely.ops import split

HERE = os.path.dirname(os.path.abspath(__file__))
X0, Y0, SX, SY = 240.0, 512.0, 0.00903, 0.00874
LANCE = [(617, 110), (680, 357)]            # its point (above the wall) and its butt (by the horse's belly), in pixels

im = cv2.imread(sys.argv[1]).astype(np.float32)
x0, y0, x1, y1 = 510, 150, 790, 436
crop = im[y0:y1, x0:x1].max(axis=2)
S = 6
big = cv2.resize(crop, None, fx=S, fy=S, interpolation=cv2.INTER_CUBIC)
mask = (big < 84).astype(np.uint8) * 255
mask[:(205 - y0) * S, :(628 - x0) * S] = 0          # (the dark edge of the wall's cap where it dips, left of his hat)
k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (int(1.5 * S) | 1, int(1.5 * S) | 1))
mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, k)     # (the lance and the reins go; the legs stay)
mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (S + 1, S + 1)))
n, lab, stats, _ = cv2.connectedComponentsWithStats(mask)
big_one = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
mask = np.where(lab == big_one, 255, 0).astype(np.uint8)
cs, hier = cv2.findContours(mask, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
main = max(cs, key=cv2.contourArea)


def metres(c):
    return [(round((x0 + px / S - X0) * SX, 3), round((Y0 - (y0 + py / S)) * SY, 3)) for px, py in c]


poly = cv2.approxPolyDP(main, 0.55 * S, True)[:, 0, :]
holes = [cv2.approxPolyDP(c, 0.55 * S, True)[:, 0, :] for i, c in enumerate(cs) if hier[0][i][3] >= 0 and cv2.contourArea(c) > 12 * S * S]
shape = Polygon(metres(poly), [metres(h) for h in holes if len(h) >= 3]).buffer(0)
if shape.geom_type != 'Polygon':
    shape = max(shape.geoms, key=lambda g: g.area)
pieces = [shape]
for g in shape.interiors:                   # cut down through each gap: pieces without holes, for triangulating
    cx = Polygon(g).centroid.x
    nxt = []
    for pc in pieces:
        nxt += [q for q in split(pc, LineString([(cx, -1.0), (cx, 5.0)])).geoms if q.area > 1e-5]
    pieces = nxt


def ring(r, ccw=True):
    c = list(r.coords)[:-1]
    if Polygon(c).exterior.is_ccw != ccw:
        c.reverse()
    return [[round(a, 3), round(b, 3)] for a, b in c]


lo = shape.bounds
out = {'outline': ring(shape.exterior), 'gaps': [ring(i, False) for i in shape.interiors],
       'pieces': [ring(pc.exterior) for pc in pieces],
       'lance': [[round((x - X0) * SX, 3), round((Y0 - y) * SY, 3)] for x, y in LANCE],
       'bounds': [round(v, 3) for v in lo],
       'source': 'traced from Street View (November 2024), the steel sheet on the welcome wall of the old road'}
json.dump(out, open(os.path.join(HERE, '..', '..', 'godot', 'data', 'quijote.json'), 'w'), separators=(',', ':'))
print('points', len(out['outline']), 'gaps', len(out['gaps']), 'pieces', len(out['pieces']), 'bounds', out['bounds'],
      'area %.2f m2' % shape.area)
if len(sys.argv) > 2:                       # a picture to check it by
    dbg = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR) // 3
    cv2.polylines(dbg, [poly.reshape(-1, 1, 2)], True, (0, 0, 255), 3)
    for h in holes:
        cv2.polylines(dbg, [h.reshape(-1, 1, 2)], True, (0, 255, 0), 3)
    cv2.imwrite(sys.argv[2], cv2.resize(dbg, None, fx=0.5, fy=0.5, interpolation=cv2.INTER_AREA))
