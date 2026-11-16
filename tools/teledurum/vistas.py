"""The kebab house of the Calle de Santa Ana photographed in the game from where Street View stood: prints the vistas=... for tools/run_tests.py.

    python tools/teledurum/vistas.py SV_FOLDER name [name ...]      (names of capturas.py's views; reads SV_FOLDER/views.json)
"""
import json, math, os, sys

if __name__ == '__main__':
    views = json.load(open(os.path.join(sys.argv[1], 'views.json')))
    out = []
    for n in sys.argv[2:]:
        v = views[n]
        d = 30.0
        h, p = math.radians(v['heading']), math.radians(v['pitch'])
        tx = v['x'] + math.sin(h) * d * math.cos(p); tz = v['z'] - math.cos(h) * d * math.cos(p)
        vfov = math.degrees(2 * math.atan(math.tan(math.radians(v['hfov'] / 2)) * 640 / 1024))
        out.append('sv_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f' % (n, v['x'], v['z'], 2.5, tx, tz, 2.5 + d * math.sin(p), vfov))
    print('vistas=' + ';'.join(out))
