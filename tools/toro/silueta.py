"""The Madridejos Osborne bull's outline, traced from the south elevation (parallel projection) of the model
"Toro en Madridejos" (3D Warehouse, by Fdiaz.osborne) as its viewer draws it: tools/toro/alzado_sur.jpg.
    python tools/toro/silueta.py  ->  godot/data/toro.json  (the outline in metres, x along the bull, y up)
"""
import json, os, sys
import cv2, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
im = cv2.imread(os.path.join(HERE, 'alzado_sur.jpg'))
crop = im[15:470, 190:620].astype(np.float32)
dark = 255 - crop.max(axis=2)                       # black sheet -> bright
S = 6
big = cv2.resize(dark, None, fx=S, fy=S, interpolation=cv2.INTER_CUBIC)
mask = (big > 150).astype(np.uint8) * 255
k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3 * S + 1, 3 * S + 1))
mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, k)    # (the thin steel members by the legs go; the horns stay)
cs, hier = cv2.findContours(mask, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
main = max(cs, key=cv2.contourArea)
x, y, w, h = cv2.boundingRect(main)
holes = [c for i, c in enumerate(cs) if hier[0][i][3] >= 0 and cv2.contourArea(c) > 50 * S * S]
poly = cv2.approxPolyDP(main, 0.7 * S, True)[:, 0, :]
H = 14.0                                            # the Osborne bulls on the roads stand 14 m from hooves to horns
m = H / h
from shapely.geometry import Polygon, LineString
from shapely.ops import split
def metres(c):
    q = [((px - x) * m, (y + h - py) * m) for px, py in c]
    return q
outer = metres(poly)
gaps = [metres(cv2.approxPolyDP(c, 0.7 * S, True)[:, 0, :]) for c in holes]     # (between the tail and the hind leg)
shape = Polygon(outer, gaps).buffer(0)
pieces = [shape]
for g in gaps:                                      # cut down through each gap: pieces without holes, for triangulating
    cx = Polygon(g).centroid.x
    nxt = []
    for pc in pieces:
        nxt += list(split(pc, LineString([(cx, -1.0), (cx, H + 1.0)])).geoms)
    pieces = nxt
def ring(r, ccw=True):
    c = list(r.coords)[:-1]
    if Polygon(c).exterior.is_ccw != ccw:
        c.reverse()
    return [[round(a, 3), round(b, 3)] for a, b in c]
out = {'height': H, 'width': round(w * m, 2), 'outline': ring(shape.exterior), 'gaps': [ring(i, False) for i in shape.interiors],
       'pieces': [ring(pc.exterior) for pc in pieces],
       'source': 'traced from the model "Toro en Madridejos" (3D Warehouse, Fdiaz.osborne)'}
pts = out['outline']
json.dump(out, open(os.path.join(HERE, '..', '..', 'godot', 'data', 'toro.json'), 'w'), separators=(',', ':'))
print('points', len(pts), 'pieces', len(out['pieces']), 'gaps', len(out['gaps']), 'width', out['width'], 'm', 'area', round(cv2.contourArea(main) * m * m, 1), 'm2')
dbg = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR) // 3
cv2.polylines(dbg, [poly.reshape(-1, 1, 2)], True, (0, 0, 255), 3)
cv2.imwrite(os.path.join(HERE, 'silueta_check.png'), cv2.resize(dbg, None, fx=0.25, fy=0.25, interpolation=cv2.INTER_AREA))
