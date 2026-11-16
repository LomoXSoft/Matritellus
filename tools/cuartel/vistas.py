"""The Tricornios' barracks photographed in the game from where Street View stood: prints the vistas=... for tools/run_tests.py.

    python tools/cuartel/vistas.py SV_FOLDER name [name ...]      (names of capturas.py's views; reads SV_FOLDER/views.json)
    python tools/cuartel/vistas.py coche                          (the patrol car parked before the steps, from all round: its marks)

Google's places for its cameras are a metre or two out. FIT: the camera of each picture as tools/cuartel/medir.py
fitted it, in the frame of godot/scripts/cuartel.gd (metres along the main front, metres out of it), and how far its
compass was turned. The avenue's camera AC was fitted to the front's outer corners; those of the Calle de Víctor
Pradera stand 3.8 m from the north fronts (not 4.8) and 0.9 m further west than Google has them.
"""
import json, math, os, sys
import medir

FIT = {'ac': (15.62, 19.26, 3.0)}
NORTH = ('va', 'vb', 'vc', 'vd', 've', 'vf')        # the cameras of the Calle de Víctor Pradera


def camera(name, v):
    medir.face('o')
    for head, cam in FIT.items():
        if name == head:
            return medir.O0[0] + medir.U0[0] * cam[0] + medir.OUT0[0] * cam[1], medir.O0[1] + medir.U0[1] * cam[0] + medir.OUT0[1] * cam[1], cam[2]
    if name.startswith(NORTH):
        x, z = medir.local((v['x'], v['z']))        # (along the main front, out of it: the north street is at x < 0)
        x, z = -3.8, z + 0.88
        return medir.O0[0] + medir.U0[0] * x + medir.OUT0[0] * z, medir.O0[1] + medir.U0[1] * x + medir.OUT0[1] * z, 1.5
    return v['x'], v['z'], 0.0


COCHE = 'vistas=coche_lado:39.33,-515.78,1.3,44.45,-516.64,0.9,45;coche_frente:45.75,-508.9,1.5,44.45,-516.64,0.9,50;coche_tras:43.2,-524.2,1.5,44.45,-516.64,0.9,50;coche_alto:42.0,-512.5,4.5,44.45,-516.64,0.8,45;coche_fachada:47.9,-515.6,1.4,44.45,-516.64,0.9,60'

if __name__ == '__main__':
    if sys.argv[1] == 'coche':                    # the patrol car parked before the steps, from all round
        print(COCHE)
        sys.exit(0)
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
