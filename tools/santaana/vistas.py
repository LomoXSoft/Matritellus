"""The convent of Santa Ana photographed in the game from where Street View stood: prints the vistas=... for
tools/run_tests.py (plain map coordinates; heights over the ground).

    python tools/santaana/vistas.py [name ...]        names of capturas.py's views (M5_f, M7_sw ...)
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import capturas

FIX = (0.0, 0.0)            # Google's cameras here, on the map: not corrected


def view(name):
    for n, key, h, p, fov in capturas.SHOTS:
        if n == name:
            pid, x, z = capturas.PANO[key]
            x += FIX[0]; z += FIX[1]
            d = 30.0
            tx = x + math.sin(math.radians(h)) * d * math.cos(math.radians(p))
            tz = z - math.cos(math.radians(h)) * d * math.cos(math.radians(p))
            vfov = math.degrees(2 * math.atan(math.tan(math.radians(fov / 2)) * 640 / 1024))
            return 'sv_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f' % (name, x, z, 2.5, tx, tz, 2.5 + d * math.sin(math.radians(p)), vfov)
    raise SystemExit('no view called ' + name)


if __name__ == '__main__':
    print('vistas=' + ';'.join(view(n) for n in sys.argv[1:]))
