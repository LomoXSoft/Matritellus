"""The Merkocarry photographed in the game from where Street View stood: prints the vistas=... for tools/run_tests.py.

    python tools/merkocarry/vistas.py SV_FOLDER name [name ...]      (names of capturas.py's views; reads SV_FOLDER/views.json)
    python tools/merkocarry/vistas.py SV_FOLDER name:dx,dz ...       (the camera moved dx, dz metres: Google's are often off)

Google's cameras are taken where it says (2.5 m over the street).
"""
import json, math, os, sys


if __name__ == '__main__':
    views = json.load(open(os.path.join(sys.argv[1], 'views.json')))
    out = []
    for arg in sys.argv[2:]:
        n, _, sh = arg.partition(':')
        dx, dz = (tuple(map(float, sh.split(','))) if sh else (0.0, 0.0))
        v = views[n]
        x, z = v['x'] + dx, v['z'] + dz
        d = 40.0
        h, p = math.radians(v['heading']), math.radians(v['pitch'])
        tx = x + math.sin(h) * d * math.cos(p); tz = z - math.cos(h) * d * math.cos(p)
        vfov = math.degrees(2 * math.atan(math.tan(math.radians(v['hfov'] / 2)) * 1000 / 1600))
        out.append('sv_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f' % (n, x, z, 2.5, tx, tz, 2.5 + d * math.sin(p), vfov))
    print('vistas=' + ';'.join(out))
