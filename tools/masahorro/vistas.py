"""The MasAhorro photographed in the game from where Street View stood: prints the vistas=... for tools/run_tests.py.

    python tools/masahorro/vistas.py SV_FOLDER name [name ...]      (names of capturas.py's views; reads SV_FOLDER/views.json)

Google's cameras are taken where it says, but for those of the lane behind the shop: Google puts them about 4 m north
of where they stood (the loading door, 3.7 m wide, is 10 m from the camera, not 6), so they are moved back (SHIFT).
"""
import json, math, os, sys

SHIFT = {'sa': (0.0, 4.0), 'sb': (0.0, 4.0), 'sc': (0.0, 4.0), 'sd': (0.0, 4.0)}      # camera: metres east, south

if __name__ == '__main__':
    views = json.load(open(os.path.join(sys.argv[1], 'views.json')))
    out = []
    for n in sys.argv[2:]:
        v = views[n]
        dx, dz = SHIFT.get(n.split('_')[0], (0.0, 0.0))
        x, z = v['x'] + dx, v['z'] + dz
        d = 40.0
        h, p = math.radians(v['heading']), math.radians(v['pitch'])
        tx = x + math.sin(h) * d * math.cos(p); tz = z - math.cos(h) * d * math.cos(p)
        vfov = math.degrees(2 * math.atan(math.tan(math.radians(v['hfov'] / 2)) * 640 / 1024))
        out.append('sv_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f' % (n, x, z, 2.5, tx, tz, 2.5 + d * math.sin(p), vfov))
    print('vistas=' + ';'.join(out))
