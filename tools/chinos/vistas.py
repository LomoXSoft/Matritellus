"""The grocer's at the point between San José and Santo Domingo photographed in the game from where Street View stood:
prints the vistas=... for tools/run_tests.py.

    python tools/chinos/vistas.py SV_FOLDER name [name ...]      (names of capturas.py's views; reads SV_FOLDER/views.json)

Not from where Google says each camera was (a metre or two out, in streets this narrow) but from where
tools/chinos/ajuste.py fitted it: FIT, camera -> the wall it was fitted to, metres along it, metres out, degrees turned.
The camera in front of the point (E) was fitted by hand to the width of the point: 10 m from it, not 12.8.
"""
import json, math, os, sys
import medir

FIT = {'NB': ('n', 19.68, 3.11, 3.8), 'NA': ('n', 9.71, 2.51, 0.9), 'NE': ('n', -0.42, 2.09, 2.5), 'SA': ('s', 7.10, 3.54, 1.5), 'SB': ('s', -1.57, 3.84, -0.5), 'SE': ('s', 16.89, 2.38, -1.0)}
E = (-272.4, 7.9)


def camera(name):
    for head, cam in (('cal_n_o', 'NB'), ('nb24', 'NB'), ('cal_n_e', 'NE'), ('ne24', 'NE'), ('n24', 'NA'), ('n19', 'NA'), ('cal_s_o', 'SB'), ('sb24', 'SB'), ('cal_s_e', 'SE'), ('se24', 'SE'), ('s24', 'SA'), ('s09', 'SA')):
        if name.startswith(head):
            wall, along, out, turn = FIT[cam]
            o, u, n, _ = medir.frame(wall)
            return o[0] + u[0] * along + n[0] * out, o[1] + u[1] * along + n[1] * out, turn
    if name.startswith('e24') or name.startswith('e19') or name.startswith('e13') or name.startswith('e09'):
        return E[0], E[1], 0.0
    return None


if __name__ == '__main__':
    views = json.load(open(os.path.join(sys.argv[1], 'views.json')))
    out = []
    for n in sys.argv[2:]:
        v = views[n]
        x, z, turn = camera(n) or (v['x'], v['z'], 0.0)
        d = 30.0
        h, p = math.radians(v['heading'] + turn), math.radians(v['pitch'])
        tx = x + math.sin(h) * d * math.cos(p); tz = z - math.cos(h) * d * math.cos(p)
        vfov = math.degrees(2 * math.atan(math.tan(math.radians(v['hfov'] / 2)) * 640 / 1024))
        out.append('sv_%s:%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.1f' % (n, x, z, 2.5, tx, tz, 2.5 + d * math.sin(p), vfov))
    print('vistas=' + ';'.join(out))
