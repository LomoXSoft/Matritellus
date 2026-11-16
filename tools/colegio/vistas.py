"""The old school photographed in the game from where Street View stood: prints the vistas=... for tools/run_tests.py.

    python tools/colegio/vistas.py SV_FOLDER name [name ...]      (names of capturas.py's views; reads SV_FOLDER/views.json)

The avenue's cameras stand some 30 m from the front: Google's place for them is near enough, except for the pictures
of March 2013, which were NOT taken from where capturas.py says (it gives them the place of the camera of 2024):
FIT has where tools/colegio/medir.py fitted them (metres along the front, metres out of it, in colegio.gd's frame).
"""
import json, math, os, sys
import medir

FIT = {'je13': (22.08, 32.65)}


def camera(name, v):
    for head, cam in FIT.items():
        if name.startswith(head):
            return medir.O[0] + medir.U[0] * cam[0] + medir.OUT[0] * cam[1], medir.O[1] + medir.U[1] * cam[0] + medir.OUT[1] * cam[1]
    return v['x'], v['z']


if __name__ == '__main__':
    views = json.load(open(os.path.join(sys.argv[1], 'views.json')))
    out = []
    for n in sys.argv[2:]:
        v = views[n]
        x, z = camera(n, v)
        d = 40.0
        h, p = math.radians(v['heading']), math.radians(v['pitch'])
        tx = x + math.sin(h) * d * math.cos(p); tz = z - math.cos(h) * d * math.cos(p)
        vfov = math.degrees(2 * math.atan(math.tan(math.radians(v['hfov'] / 2)) * 640 / 1024))
        out.append('sv_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f' % (n, x, z, 2.5, tx, tz, 2.5 + d * math.sin(p), vfov))
    print('vistas=' + ';'.join(out))
