"""The Plazuela del Toledano photographed in the game from where Street View stood: prints the vistas=... for
tools/run_tests.py.

    python tools/toledano/vistas.py SV_FOLDER name [name ...]      (names of capturas.py's views; reads SV_FOLDER/views.json)
    python tools/toledano/vistas.py aire                           (from the air)

FIT: how far Google has each camera from where it was, on the map (x, z), once measured (medir.py); none yet.
"""
import json, math, os, sys

FIT = {}


if __name__ == '__main__':
    if sys.argv[1] == 'aire':
        print('vistas=tol_aire:-368,-20,38,-368,-42,0,50;tol_aire_s:-352,-70,22,-368,-42,0,55')
        sys.exit()
    views = json.load(open(os.path.join(sys.argv[1], 'views.json')))
    out = []
    for n in sys.argv[2:]:
        v = views[n]
        dx, dz = FIT.get(n.split('_')[0], (0.0, 0.0))
        x, z = v['x'] + dx, v['z'] + dz
        d = 40.0
        h, p = math.radians(v['heading']), math.radians(v['pitch'])
        tx = x + math.sin(h) * d * math.cos(p); tz = z - math.cos(h) * d * math.cos(p)
        vfov = math.degrees(2 * math.atan(math.tan(math.radians(v['hfov'] / 2)) * 640 / 1024))
        out.append('sv_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f' % (n, x, z, 2.5, tx, tz, 2.5 + d * math.sin(p), vfov))
    print('vistas=' + ';'.join(out))
