"""The people's university and the stationer's photographed in the game from where Street View stood: prints the
vistas=... for tools/run_tests.py.

    python tools/comunal/vistas.py SV_FOLDER name [name ...]      (names of capturas.py's views; reads SV_FOLDER/views.json)

Google has the cameras of the Calle de los Arcos some 2.2 m further north than they were (tools/comunal/medir.py:
fitted to the ends of the garden wall and of the front): FIT is that shift, in the frame of godot/scripts/comunal.gd
(metres along the front, metres out of it).
"""
import json, math, os, sys
import medir

FIT = (-2.2, 0.0)
STREET = ('a', 'b', 'c', 'd', 'e')              # the cameras of the Calle de los Arcos


def camera(name, v):
    if name.startswith(STREET):
        x, z = medir.local((v['x'], v['z']))
        x, z = x + FIT[0], z + FIT[1]
        return medir.O[0] + medir.U[0] * x + medir.OUT[0] * z, medir.O[1] + medir.U[1] * x + medir.OUT[1] * z, 0.0
    return v['x'], v['z'], 0.0


if __name__ == '__main__':
    views = json.load(open(os.path.join(sys.argv[1], 'views.json')))
    out = []
    for n in sys.argv[2:]:
        v = views[n]
        x, z, turn = camera(n, v)
        d = 40.0
        h, p = math.radians(v['heading'] + turn), math.radians(v['pitch'])
        tx = x + math.sin(h) * d * math.cos(p); tz = z - math.cos(h) * d * math.cos(p)
        vfov = math.degrees(2 * math.atan(math.tan(math.radians(v['hfov'] / 2)) * 640 / 1024))
        out.append('sv_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f' % (n, x, z, 2.5, tx, tz, 2.5 + d * math.sin(p), vfov))
    print('vistas=' + ';'.join(out))
