"""The Street View pictures the house of the Calle de Matías Pérez is built from (the user, 17 November 2026: "Nuevo
proyecto. Matias Pérez 16"; Texturas's house matias_16). They are Google's: NOT kept in the repository, only this list.
Writes views.json beside them.

    python tools/matias/capturas.py OUT_FOLDER [name ...]

Google's car went along the street in November 2024, October 2019 and May 2009 at the same spots. Every camera:
python tools/molino/panos.py cerca zUPnD-kJCxRwgKgGczw46A -266.4 -338.4 25
"""
import json, math, os, sys, urllib.request
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'molino'))
import panos

C = {'m0': ('zUPnD-kJCxRwgKgGczw46A', -271.30, -337.19), 'm0_19': ('dTg8DHp35hA4O8mwR1A4Iw', -271.30, -337.19), 'm0_09': ('FV2IKz8XkXcsD5sHLPprwA', -271.30, -337.19),
     'm1': ('WTx1FGJ8hm0BDnFrVky2Sw', -263.02, -331.20), 'm1_19': ('9Auxdg-inHCaiWxPOW2ndg', -263.02, -331.20), 'm1_09': ('wbEXzBIaN7bNA7Xo-9qu1Q', -263.02, -331.20),
     'm2': ('Gwi_NmzXO5nUuVbsFeS3Lw', -279.71, -343.17), 'm2_19': ('GFenu_jx7H9KSt8U_uIBKA', -279.71, -343.17),
     'm3': ('no1-hEbIE79p0szaj8XJeQ', -254.83, -325.31), 'm4': ('wR0wtwujbIA281PlznKtmQ', -288.30, -348.91)}
FRONT = (-266.36, -338.40)                       # (the middle of its front, on the map)

SHOTS = []
for k, c in C.items():
    SHOTS.append((k, c, FRONT, 10, 80))
for k in ('m0', 'm1', 'm0_19', 'm1_19', 'm0_09'):
    SHOTS.append((k + '_up', C[k], FRONT, 30, 80))

if __name__ == '__main__':
    out = sys.argv[1]
    only = set(sys.argv[2:])
    os.makedirs(out, exist_ok=True)
    path = os.path.join(out, 'views.json')
    views = json.load(open(path)) if os.path.exists(path) else {}
    for name, (pid, x, z), at, p, fov in SHOTS:
        if only and name not in only:
            continue
        h = math.degrees(math.atan2(at[0] - x, -(at[1] - z))) % 360
        f = os.path.join(out, name + '.jpg')
        if not os.path.exists(f):
            url = 'https://streetviewpixels-pa.googleapis.com/v1/thumbnail?panoid=%s&cb_client=maps_sv.tactile&w=1600&h=1000&yaw=%g&pitch=%g&thumbfov=%g' % (pid, h, -p, fov)
            try:
                open(f, 'wb').write(urllib.request.urlopen(urllib.request.Request(url, headers=panos.UA), timeout=40).read())
            except Exception as e:
                print('  could not fetch', name, e); continue
        views[name] = {'pano': pid, 'x': x, 'z': z, 'heading': round(h, 1), 'pitch': p, 'hfov': fov}
    json.dump(views, open(path, 'w'), indent=0)
    print(len(views), 'views in', out)
