"""The Tricornios' roundabout photographed in the game from where Street View stood: prints the vistas=... for
tools/run_tests.py.

    python tools/rotonda/vistas.py SV_FOLDER name [name ...]      (names of capturas.py's views; reads SV_FOLDER/views.json)

Round this roundabout Google's cameras agree with the map to a quarter of a metre (the mast's bearings): no shift.
"""
import json, math, os, sys

OUT = 0.0
U = (0.685, 0.729)              # the front's way (castilla_17 of the map)
N = (-U[1], U[0])               # out to the avenue


if __name__ == '__main__':
    views = json.load(open(os.path.join(sys.argv[1], 'views.json')))
    out = []
    for n in sys.argv[2:]:
        v = views[n]
        x, z = v['x'] + N[0] * OUT, v['z'] + N[1] * OUT
        d = 40.0
        h, p = math.radians(v['heading']), math.radians(v['pitch'])
        tx = x + math.sin(h) * d * math.cos(p); tz = z - math.cos(h) * d * math.cos(p)
        vfov = math.degrees(2 * math.atan(math.tan(math.radians(v['hfov'] / 2)) * 640 / 1024))
        out.append('sv_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f' % (n, x, z, 2.5, tx, tz, 2.5 + d * math.sin(p), vfov))
    print('vistas=' + ';'.join(out))
